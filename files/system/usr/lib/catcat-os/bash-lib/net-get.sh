#!/usr/bin/env bash
get_ghpkg_url() {
    local repo="${1}" include_pattern="${2:-}" exclude_pattern="${3:-}" sha="${4:-}"
    local gh_api="https://api.github.com/repos/${repo}/releases/latest"
    local jq_filter='.assets[] | select(.name | test($inc) and (if $exc != "" then test($exc) |
                        not else true end)).browser_download_url'

    if [[ -n "${GHPKG_VERSION:-}" ]]; then
        gh_api="https://api.github.com/repos/${repo}/releases/tags/${GHPKG_VERSION}"
    elif [[ ${GHPKG_PRERELEASE:-0} -eq 1 ]]; then
        gh_api="https://api.github.com/repos/${repo}/releases?per_page=10"
        jq_filter='map(select(.prerelease == true)) | first | '"${jq_filter}"
    fi

    [[ -n "${JQ_FILTER:-}" ]] && jq_filter="${JQ_FILTER}"

    local ii response url vals=()
    for ii in {1..5}; do
        { brief_untrace; } 2>/dev/null
        response="$(curl_fetch "${gh_api}")"
        { brief_untrace; } 2>/dev/null
        url=$(jq -r --arg inc "${include_pattern}" \
                    --arg exc "${exclude_pattern}" "${jq_filter}" <<< "${response}")
        if [[ -n "${url}" ]]; then
            if [[ -n "${sha}" ]]; then
                jq_filter="${jq_filter%.browser_*}.digest"
                digest=$(jq -r --arg inc "${include_pattern}" \
                               --arg exc "${exclude_pattern}" "${jq_filter}" <<< "${response}")
                printf '%s\n%s\n' "${url}" "${digest#*:}"
            else
                printf '%s\n' "${url}"
            fi
            return 0
        fi
        sleep 0.5
    done

    err "Max attempts reached..."
    die "Unable to retrieve latest package URL from repo: ${repo}"
}

place_executable() {
    local find_exec_dir="${1}" exec_name="${2}" bin_dir="${BIN_DIR:-/usr/bin}"
    local found_execs exec_types="(application|text)/x-(.*executable|elf|.*script|.*python|perl|ruby)"
    readarray -t found_execs < <(find "${find_exec_dir}" -type f -exec file --mime '{}' \; | \
                                    grep -E "${exec_types}" | \
                                    cut -d: -f1 | \
                                    grep -E "/${exec_name}\$")

    [[ ${#found_execs[@]} -eq 0 ]] && die "No executable found: ${exec_name}"
    [[ ${#found_execs[@]} -gt 1 ]] &&
        die "More than 1 executable with same name\n$(printf '%s\n' "${found_execs[@]}")"

    # When called inside get_ghpkg use pkg_name
    [[ -n "${pkg_name:-}" ]] && exec_name="${pkg_name}"

    log "DEBUG" "Placing executable: ${bin_dir}/${exec_name}"
    ensure_dir "${bin_dir}"
    cp ${VERBOSE:+-v} -f -- "${found_execs[0]}" "${bin_dir}/${exec_name}"
    chmod ${VERBOSE:+-v} +x -- "${bin_dir}/${exec_name}"
}

get_ghpkg() {
    local bin_dir="${BIN_DIR:-/usr/bin}" libexec_dir="${LIBEXEC_DIR:-/usr/libexec}"
    local pkg_name pkg_repo pkg_regx pkg_negx="" overwrite=0 islibexec=0
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --name)    pkg_name="${2}"; shift ;; # Set package name
            --repo)    pkg_repo="${2}"; shift ;; # GitHub repo (owner/repo)
            --regx)    pkg_regx="${2}"; shift ;; # Filter release assets by regex
            --negx)    pkg_negx="${2}"; shift ;; # Exclude assets matching by regex
            --force)   overwrite=1    ; shift ;; # Overwrite package
            --libexec) islibexec=1    ;;         # Installs package contents into libexec
            *)         die "Unknown option: ${1}" ;;
        esac
        shift
    done

    if [[ ${overwrite} -eq 0 ]]; then
        local lib_pkgd="${libexec_dir}/${pkg_name}"
        [[ ${islibexec} -eq 1 && -d "${lib_pkgd}" && -n "$(ls -A "${lib_pkgd}")" ]] && {
            log "NOTE" "Package skipped - Non-empty directory exists: ${lib_pkgd}"
            return 0; }

        [[ ${islibexec} -eq 0 && -x "${bin_dir}/${pkg_name}" ]] && {
            log "NOTE" "Package skipped - Executable exists: ${bin_dir}/${pkg_name}"
            return 0; }
    fi

    # Retrieve metadata
    local pkg_vals pkg_url pkg_sha pkg_archive

    readarray -t pkg_vals < <(get_ghpkg_url "${pkg_repo}" "${pkg_regx}" "${pkg_negx:-musl}" "sha")
    [[ ${#pkg_vals[@]} -eq 0 ]] && die "Unable to retrieve latest package URL from repo: ${pkg_repo}"

    pkg_url="${pkg_vals[0]}"
    pkg_sha="${pkg_vals[1]}"
    pkg_archive="${TMP_DIR:-/tmp/get_ghpkg}/${pkg_name}/$(basename "${pkg_url}")"

    ensure_dir "$(dirname "${pkg_archive}")"
    curl_get "${pkg_archive}" "${pkg_url}"

    # Verify checksum with retries
    if [[ -n "${pkg_sha}" && "${pkg_sha}" != "null" ]]; then
        for ii in {0..5}; do
            sha256sum -c <<< "${pkg_sha}  ${pkg_archive}" && break

            [[ ${ii} -eq 5 ]] &&
                die "Max attempts reached, package checksum verification failed: ${pkg_name}"

            err "Checksum mismatch for package: ${pkg_name}"
            log "INFO" "Retrying ${ii}..."
            rm "${pkg_archive}"
            sleep 0.5
            curl_get "${pkg_archive}" "${pkg_url}"
        done
        unset ii
    else
        log "WARN" "Checksum skipped, package digest unavailable in repo: ${pkg_repo}"
    fi

    # Install a direct package
    if [[ ${DIRECT_GHPKG:-0} -eq 1 ]]; then
        place_executable "$(dirname "${pkg_archive}")" "$(basename "${pkg_url}")"
        return 0
    fi

    # Extract and install
    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    # Detect top populated directories
    readarray -t auto_fold_dir < <(populated_or_afile_dirs "${pkg_archive}.extract")

    if [[ ${islibexec} -eq 1 ]]; then
        local libexec_dir="${LIBEXEC_DIR:-/usr/libexec}"
        log "DEBUG" "Copying contents of ${auto_fold_dir[0]} in ${libexec_dir}/${pkg_name}"
        ensure_dir "${libexec_dir}/${pkg_name}"
        ocopy "${auto_fold_dir[0]}" "${libexec_dir}/${pkg_name}"
    else
        place_executable "${auto_fold_dir[0]}" "${pkg_name}"
    fi
}

get_ghraw() {
    local destfile="" dest_dir="" repo_raw="" repo_dir="" overwrite=0 ffile
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --dstf)  destfile="${2}"; shift 2   ;; # Output to a file
            --dstd)  dest_dir="${2}"; shift 2   ;; # Fetch file(s) in a directory
            --repo)  repo_raw="${2}"; shift 2   ;; # GitHub repo (owner/repo)
            --repod) repo_dir="${2}"; shift 2   ;; # Subdirectory in the repo
            --force) overwrite=1; shift         ;; # Set overwrite flag
            -f|--flist) shift; break            ;; # File or list of files to fetch
            *)       die "Unknown option: ${1}" ;;
        esac
    done
    local gh_api="https://api.github.com/repos/${repo_raw}" branch="" raw_url="" dest_path=""

    for ffile in "$@"; do
        dest_path="${destfile:-"${dest_dir}/${ffile}"}"
        if [[ -f "${dest_path}" && ${overwrite} -ne 1 ]]; then
            log "NOTE" "Fetch skipped - Overwrite is disabled, file exists: ${dest_path}"
            continue
        fi
        [[ -z "${branch}" ]] &&
        branch="${GIT_BRANCH:-"$(curl_fetch "${gh_api}" | jq -r '.default_branch')"}"
        raw_url="https://raw.githubusercontent.com/${repo_raw}/refs/heads/${branch}"
        ensure_dir "$(dirname "${dest_path}")"
        curl_get "${dest_path}" "${raw_url}/${repo_dir:+${repo_dir}/}${ffile}"
    done
}

get_fonts() {
    local font_name="${1}" font_url="${2}"
    local fonts_dir="${FONTS_DIR:-/usr/share/fonts}" tmpdir="${TMP_DIR:-/tmp/get_fonts}"
    local font_dest="${fonts_dir}/${font_name}" font_tmpd="${tmpdir}/${font_name}"
    local url_file fontfile

    [[ -z "${font_url}" ]] &&
    font_dest="${fonts_dir}/nerd-fonts/${font_name}"
    mkdir ${VERBOSE:+-v} -p "${font_tmpd}" "${font_dest}"
    if [[ -d "${font_dest}" && -n "$(ls -A "${font_dest}")" ]]; then
        log "NOTE" "Font skipped - Non-empty directory exists: ${font_dest}"
    else
        if [[ -z "${font_url}" ]]; then
            font_url="$(get_ghpkg_url 'ryanoasis/nerd-fonts' '.' 2>/dev/null | \
                        grep -i "/${font_name}\.tar")"
            if [[ -z "${font_url}" ]]; then
                err "No Nerd Font with name: ${font_name}"
                die "No URL provided to get the font"
            fi
        fi
        url_file="$(basename "${font_url}")"
        log "INFO" "Adding font(s): ${font_name}"
        log "INFO" "From URL: ${font_url}"

        case "${font_url}" in
            *.zip|*.7z|*.rar|*.tar.*|*.tar|*.tbz|*.tbz2|*.tgz|*.tlz|*.txz|*.tzst)
                curl_get "${tmpdir}/${url_file}" "${font_url}"
                unarchive "${tmpdir}/${url_file}" "${font_tmpd}" >/dev/null
                ;;
            *.otf|*.ttf)
                curl_get "${font_tmpd}/${url_file}" "${font_url}"
                ;;
            *.git)
                git clone --depth 1 "${font_url}" "${font_tmpd}"
                ;;
            *)
                err "Fonts can only be added from URL pointing to an archive format, font file (.otf/.ttf) or git repo (.git)"
                die "Unsupported URL: ${font_url}"
                ;;
        esac
        find "${font_tmpd}" -type f -name "*.otf" -o -name "*.ttf" | while read -r fontfile; do
            cp ${VERBOSE:+-v} -f "${fontfile}" "${font_dest}"/
        done
    fi
}
