#!/usr/bin/env bash
bak_before() {
    [[ -e "${1}" ]] || { log "WARN" "Does not exists: ${1}"; return 0; }
    if [[ ! -e "${1}.og.bak" ]]; then
        cp ${VERBOSE:+-v} -drf -- "${1}" "${1}.og.bak" ||
            { err "Backup failed for orignal ${1}"; return 1; }
    fi
    cp ${VERBOSE:+-v} -drf -- "${1}" "${1}.bak" || { err "Backup failed for ${1}"; return 1; }
}

bakstore() {
    if [[ -d "${1}" && ! -d "${1}.bak" ]]; then
        mv ${VERBOSE:+-v} -- "${1}" "${1}.bak"
    fi
}

bakrestore() { mv ${VERBOSE:+-v} -- "${1}.bak" "${1}"; }

unarchive() {
    local archive="${1}" dest="${2}"

    [[ -z "${archive}" || -z "${dest}" ]] && die "No archive or destination path was provided"

    ensure_dir "${dest}"
    case "${archive,,}" in
        *.zip)
            log "DEBUG" "Extracting ZIP archive in: ${dest}"
            unzip "${archive}" -d "${dest}"
            ;;
        *.7z)
            log "DEBUG" "Extracting 7Z archive in: ${dest}"
            7z x -o"${dest}" "${archive}"
            ;;
        *.rar)
            log "DEBUG" "Extracting RAR archive in: ${dest}"
            cd "${dest}" || return 1
            unrar x "${archive}"
            cd -         || return 1
            ;;
        *.tar.*|*.tar|*.tbz|*.tbz2|*.tgz|*.tlz|*.txz|*.tzst)
            log "DEBUG" "Extracting TAR archive in: ${dest}"
            tar ${VERBOSE:+-v} -xf "${archive}" -C "${dest}"
            ;;
        *)
            die "Unknown archive file: ${archive}"
            ;;
    esac
}

ocopy() {
    local verbose=0 skip_perms=1 spray_mode=1 over_write=1 taropt paths=() ttargs=() xtargs=()

    # SC2030 - Modification of variable is local (to subshell caused by (..) group)
    # shellcheck disable=SC2030
    _otar_strm() (
        set -o pipefail
        local srcd_path="${1}"; shift
        [[ ${over_write} -eq 0 ]] && xtargs+=("--keep-old-files")
        [[ ${skip_perms} -eq 1 ]] && xtargs+=("--no-same-owner" "--no-same-permissions")

        tar -C "${srcd_path}" "${ttargs[@]}" -cf - -- "$@" | \
        tar -C "${dest_path}" "${xtargs[@]}" -xf -
    )

    # SC2031 - Variable was modified in a subshell. That change might be lost.
    # shellcheck disable=SC2031
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -v|--verbose)
                verbose=1
                xtargs+=("-v")
                ;;
            -a|--archive)
                ttargs+=("--xattrs" "--xattrs-include=*" "--acls" "--selinux")
                xtargs+=("--xattrs" "--xattrs-include=*" "--acls" "--selinux")
                ;;
            --keep-perms)
                skip_perms=0
                ;;
            --no-force)
                over_write=0
                ;;
            --no-spray)
                spray_mode=0
                ;;
            --ttar-opts|--xtar-opts)
                case "${1}" in
                    --ttar-opts) taropt=tt ;;
                    --xtar-opts) taropt=xt ;;
                    *) err "Unknown option ${1}"; return 1 ;;
                esac
                ;;
            --)
                shift
                paths+=("$@")
                break
                ;;
            --*)
                [[ -z "${taropt}" ]] && { err "Unknown option ${1}"; return 1; }
                case "${taropt}" in
                    tt) ttargs+=("${1}") ;;
                    xt) xtargs+=("${1}") ;;
                    *) err "Unknown option ${1}"; return 1 ;;
                esac
                ;;
            -*)
                err "Unknown option ${1}"; return 1
                ;;
             *)
                paths+=("${1}")
                ;;
        esac
        shift
    done

    [[ ${#paths[@]} -lt 2 ]] && { err "Provide source and destination paths"; return 1; }

    local dest_path="${paths[${#paths[@]}-1]}" rem_paths=("${paths[@]:0:${#paths[@]}-1}") path

    for path in "${rem_paths[@]}"; do
        if [[ ! -e "${path}" && ! -L "${path}" ]]; then
            err "Source does not exist: ${path}"; return 1
        fi
    done

    if [[ ${#rem_paths[@]} -gt 1 ]]; then
        local prnt_srcd="" chld_srcs=() path prnt chld
        ensure_dir "${dest_path}" || { err "Ocopy failed"; return 1; }
        for path in "${rem_paths[@]}"; do
            prnt="$(dirname -- "${path}")"
            chld="$(basename -- "${path}")"
            [[ "${path}" == "/" ]] && { prnt="/"; chld="."; }

            if [[ -n "${prnt_srcd}" && "${prnt_srcd}" != "${prnt}" ]]; then
                _otar_strm "${prnt_srcd}" "${chld_srcs[@]}" || { err "Ocopy failed"; return 1; }
                chld_srcs=()
            fi
            prnt_srcd="${prnt}"
            chld_srcs+=("${chld}")
        done
        if [[ -n "${prnt_srcd}" ]]; then
            _otar_strm "${prnt_srcd}" "${chld_srcs[@]}" || { err "Ocopy failed"; return 1; }
        fi
    else
        local srce_path="${rem_paths[0]}" srce_prnt srce_chld
        srce_prnt="$(dirname -- "${srce_path}")"
        srce_chld="$(basename -- "${srce_path}")"
        [[ "${srce_path}" == "/" ]] && { srce_prnt="/"; srce_chld="."; }

        local dest_prnt dest_chld dest_temp
        dest_prnt="$(dirname -- "${dest_path}")"
        dest_chld="$(basename -- "${dest_path}")"
        [[ "${dest_path}" == "/" ]] && { dest_prnt="/"; dest_chld="."; }

        if [[ -d "${srce_path}" ]]; then
            [[ ${spray_mode} -eq 1 ]] && { srce_prnt="${srce_path}"; srce_chld="."; }
            ensure_dir "${dest_path}" || { err "Ocopy failed"; return 1; }
            _otar_strm "${srce_prnt}" "${srce_chld}" || { err "Ocopy failed"; return 1; }
            return 0
        fi

        if [[ -d "${dest_path}" ]]; then
            _otar_strm "${srce_prnt}" "${srce_chld}" || { err "Ocopy failed"; return 1; }
            return 0
        fi

        [[ ${over_write} -eq 0 && -e "${dest_path}" ]] &&
            { err "Path exists on destination: ${dest_path}"; return 1; }
        dest_temp="${dest_prnt}/.ocopy_temp_$$"
        dest_path="${dest_temp}"
        ensure_dir "${dest_path}" >/dev/null || { err "Ocopy failed"; return 1; }
        _otar_strm "${srce_prnt}" "${srce_chld}" ||
            { err "Ocopy failed"; rm -rf -- "${dest_temp}"; return 1; }
        mv -f -- "${dest_temp}/${srce_chld}" "${dest_prnt}/${dest_chld}" ||
            { err "Ocopy failed"; rm -rf -- "${dest_temp}"; return 1; }
        rm -rf -- "${dest_temp}"
    fi
}
