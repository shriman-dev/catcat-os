#!/usr/bin/env bash
# Color formatting
declare -r black=$'\033[30m'
declare -r white=$'\033[38;2;250;235;215m'
declare -r red=$'\033[31m'
declare -r green=$'\033[32m'
declare -r yellow=$'\033[33m'
declare -r blue=$'\033[34m'
declare -r magenta=$'\033[35m'
declare -r purple="${magenta}"
declare -r pink=$'\033[38;2;255;20;146m'
declare -r cyan=$'\033[36m'

declare -r darkorange=$'\033[38;2;255;129;3m'
declare -r darkgrey=$'\033[38;2;168;168;168m'
declare -r darkgray="${darkgrey}"
declare -r lightgrey=$'\033[37m'
declare -r lightgray="${lightgrey}"
declare -r lightred=$'\033[38;2;255;114;118m'
declare -r lightgreen=$'\033[38;2;146;240;146m'
declare -r lightyellow=$'\033[38;2;255;255;224m'
declare -r lightblue=$'\033[38;2;172;215;230m'
declare -r lightmagenta="${pink}"
declare -r lightcyan=$'\033[38;2;224;255;255m'
declare -r lightpink=$'\033[38;2;255;181;192m'

# Text Formating
declare -r bold=$'\033[1m'
declare -r dim=$'\033[2m'
declare -r underline=$'\033[4m'
declare -r blink=$'\033[5m'
declare -r invert=$'\033[7m'
declare -r highlight="${invert}"
declare -r hidden=$'\033[8m'

# Remove Text Formating
declare -r normal=$'\033[0m'
declare -r noc="${normal}" # No Color
declare -r unbold=$'\033[22m'
declare -r undim=$'\033[22m'
declare -r nounderline=$'\033[24m'
declare -r unblink=$'\033[25m'
declare -r uninvert=$'\033[27m'
declare -r unhide=$'\033[28m'

QUIET=${QUIET:-false}
VERBOSE=${VERBOSE:-2}

# Logging with optional verbose output
# Disable log message tracing by running in subshell
log() (
    { set +x; } 2>/dev/null
    local level="${1^^}" color; shift
    local msg="$*" datetime=""

    [[ ${QUIET} == true ]] && return 0
    [[ "${level}" == "DEBUG" && ${VERBOSE:-0} -le 1 ]] && return 0
    [[ ${VERBOSE:-0} -ge 3 ]] && datetime="$(printf '%([%Y-%m-%d %H:%M:%S])T \n')"

    case "${level}" in
        DEBUG) color="${cyan}"   ;;
        INFO)  color="${green}"  ;;
        NOTE)  color="${blue}"   ;;
        WARN)  color="${yellow}" ;;
        ERROR) color="${red}"    ;;
        *)     return 1 ;;
    esac

    printf "%s\n"  "${bold}${datetime}${color}[${level}]${noc} ${msg}"
)

# Error handling with optional pre-exit function call
die() {
    local pre_exit_hook="${2:-}"
    [[ -n "${pre_exit_hook}" ]] && { ${pre_exit_hook} || true; }
    log "ERROR" "${1}" >&2; exit 1
}

err() { log "ERROR" "${1}" >&2; }

brief_trace() {
    if [[ $- != *x* ]]; then
        brief_trace=true
        set -x
    elif [[ ${brief_trace:-} == true ]]; then
        set +x
        unset brief_trace
    fi
}

brief_untrace() {
    if [[ $- == *x* ]]; then
        brief_untrace=true
        set +x
    elif [[ ${brief_untrace:-} == true ]]; then
        set -x
        unset brief_untrace
    fi
}

## Function to generate a choice selection and return the selected choice
# CHOICE=$(Choice option1 option2 "option 3")
# *user selects "option 3"*
# echo "$CHOICE" will return "option 3"
function Choose() {
    local CHOICE
    CHOICE=$(ugum choose "$@")
    echo "${CHOICE}"
}

## Function to generate a confirm dialog and return the selected choice
# CHOICE=$(Confirm "Are you sure you want to do this?")
# *user selects "No"*
# echo "$CHOICE" will return "1"
# 0 = Yes
# 1 = No
function Confirm() {
    ugum confirm "$@"
    echo $?
}

# Function to generate background color from foreground color
# option 38 (foreground) which can be flipped to 48 (background)
# NOTE: doublequote the color or future calls to bg will error out!
# option 38 (foreground) which can be flipped to 48 (background)
# bgblue=$(Bg "$blue")
# echo "${bgblue}text now has blue background${normal} this text has no background color"
function Bg() {
    local COLOR="${1}"
    echo "${COLOR}" | sed -E 's/\[3([0-8]{1,1})/\[4\1/'
}

# Function to generate a clickable link, you can call this using
function Urllink() {
    local URL="${1}" TEXT="${2}"
    # Generate a clickable hyperlink
    printf "\033]8;;%s\033\\%s\033]8;;\033\\\n" "${URL}" "${TEXT}${noc}"
}

# Function to generates a centered text header
# With customizable padding character, width, and symmetrical padding
symmetric_heading() {
    local text="$1" padding_char="${2:-#}" output_width=${3:-75} color_var="${4:-noc}"
    local -n color="${color_var}"
    local total=$(( output_width - ${#text} - 2 ))

    if (( total < 0 )); then
        err "Text too long for width ${output_width}"
        return 1
    fi

    # Calculate padding: left gets half, right gets the remainder (handles odd numbers)
    local left right left_pad right_pad
    left=$(( total / 2 ))
    right=$(( total - left ))
    printf -v left_pad "%${left}s"; left_pad=${left_pad// /"${padding_char}"}
    printf -v right_pad "%${right}s"; right_pad=${right_pad// /"${padding_char}"}

    printf "%s %s %s\n" "${color}${left_pad}" "${text}" "${right_pad}${noc}"
}

# Same as above but with upper and lower borders using given character
enclosed_heading() {
    local text="${1}" padding_char="${2:-#}" output_width=${3:-75} border
    local -n color_ref="${4:-noc}"
    printf -v border "%${output_width}s"; border=${border// /"${padding_char}"}

    printf "\n%s\n" "${color_ref}${border}${noc}"
    symmetric_heading "${text}" "${padding_char}" "${output_width}" "${4:-noc}"
    printf "%s\n\n" "${color_ref}${border}${noc}"
}

cmd_test_timer() {
    local endt totaltime
    if [[ -n "${_cmd_test_timer_start}" ]]; then
        endt=$(( EPOCHSECONDS - _cmd_test_timer_start ))
        totaltime="$(printf "%02d:%02d:%02d\n" $((endt/3600)) $((endt%3600/60)) $((endt%60)))"
        echo "${totaltime}"
    fi
}

need_root() {
    [[ ${EUID} -eq 0 ]] || die "This operation requires root privileges"
}

exit_if_root() {
    [[ ${EUID} -eq 0 ]] && die "Cannot run as root"
    [[ "${USER}" == "gdm" ]] && die "Cannot run as gdm user"
    [[ "${HOME}" =~ (/run/gdm|/var/lib/gdm) ]] && die "Cannot run as gdm user"
}

# Quiet mode handling function
_quiet_exec() {
    local cmd="$*"
    if [[ ${QUIET} == true ]]; then
        ${cmd} >/dev/null
    else
        ${cmd}
    fi
}

run_as_users() {
    set -x
    local cmd="${1}"; shift
    local args run_cmd running_user some_user_id some_user
    args=("$@")

    if declare -F "${cmd}" >/dev/null; then
        run_cmd="$(declare -f "${cmd}"); ${cmd}"
    elif type -f "${cmd}" >/dev/null; then
        run_cmd="${cmd}"
    else
        die "Not an executable or a shell function: ${cmd}"
    fi

    for running_user in /run/user/*; do
        some_user_id="$(basename "${running_user}")"
        some_user="$(id -un "${some_user_id}")"
        if [[ ! "${some_user}" =~ ^(root|gdm)$ ]]; then
            log "DEBUG" "Running given command as user: ${some_user}"
            sudo -u "${some_user}" bash -c 'exec "$@"' _ "${run_cmd}" "${args[@]}"
        fi
    done
    set +x
}

notify_users() {
    local running_user some_user_id some_user
    if systemctl is-active display-manager; then
        for running_user in /run/user/*; do
            some_user_id="$(basename "${running_user}")"
            some_user="$(id -un "${some_user_id}")"
            log "DEBUG" "Sending notification to user: ${some_user}"
            sudo -u "${some_user}" \
                    DBUS_SESSION_BUS_ADDRESS=unix:path="/run/user/${some_user_id}/bus" \
                    notify-send -i "${1}" -a "${2}" "${3}" "${4}"
        done
    else
        err "Notification failed: display-manager was not running."
    fi
}

ensure_file() {
    local _file
    for _file in "$@"; do
        if [[ ! -f "${_file}" ]]; then
            touch "${_file}" || die "Failed touch file: ${_file}"
        fi
    done
}

ensure_dir() {
    local _dir
    for _dir in "$@"; do
        if [[ ! -d "${_dir}" ]]; then
            mkdir ${VERBOSE:+-v} -p "${_dir}" || die "Failed create directory: ${_dir}"
        fi
    done
}

check_file_inplace() {
    local _file
    for _file in "$@"; do
        if [[ -f "${_file}" ]]; then
            log "DEBUG" "File is in place: ${_file}"
        else
            die "File does not exist in place: ${_file}"
        fi
    done
}

bak_before() {
    if [[ -e "${1}" ]]; then
        if [[ ! -e "${1}.og.bak" ]]; then
            cp ${VERBOSE:+-v} -drf "${1}" "${1}.og.bak" || err "Backup failed for orignal ${1}"
        fi
        cp ${VERBOSE:+-v} -drf "${1}" "${1}.bak" || err "Backup failed for ${1}"
    fi
}

bakrestore() {
    if [[ -e "${1}.bak" ]]; then
        mv ${VERBOSE:+-v} "${1}.bak" "${1}"
    else
        mv ${VERBOSE:+-v} "${1}" "${1}.bak"
    fi
}

ocopy() {
    local verbose="" src="" dst="" excludes=()

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -v) verbose="-v" ;;
             *)
                if [[ -z "${src}" ]]; then
                    src="${1}"
                elif [[ -z "${dst}" ]]; then
                    dst="${1}"
                else
                    excludes+=("--exclude=${1}")
                fi
                ;;
        esac
        shift
    done

    ensure_dir "${dst}"
    tar -C "${src}" "${excludes[@]}" -cf - . | \
    tar "${verbose}" \
        --touch \
        --no-same-owner \
        --no-same-permissions \
        -C "${dst}" -xf -
}

# Checks if last modification time of file/directory is older than a specified seconds
is_older_than() {
    local target_path threshold_sec target_mtime_sec current_time_sec targett_aged_sec
    target_path="${1%/}"
    threshold_sec=${2}

    [[ -e "${target_path}" ]] || die "Does not exist: ${target_path}"
    [[ "${threshold_sec}" =~ ^[0-9]+$ ]] || die "Not an integer: ${threshold_sec}"

    target_mtime_sec=$(stat -c "%Y" "${target_path}")
    current_time_sec=${EPOCHSECONDS}
    targett_aged_sec=$(( current_time_sec - target_mtime_sec ))

    if [[ ${targett_aged_sec} -gt ${threshold_sec} ]]; then
        return 0
    else
        return 1
    fi
}

replace_add() {
    if grep -qi "${1}" "${3}"; then
        sed -i -e "s|.*${1}.*|${2}|" "${3}"
    else
        echo "${2}" >> "${3}"
    fi
}

check_filesystem() {
    local mode="${1}"; shift
    local path_a="${1}" path_b="${2}" fs_a fs_b

    [[ -e "${path_a}" ]] || die "Does not exist: ${path_a}"
    [[ -e "${path_b}" ]] || die "Does not exist: ${path_b}"

    fs_a="$(findmnt -n -o SOURCE --target "${path_a}" | cut -d'[' -f1)"
    fs_b="$(findmnt -n -o SOURCE --target "${path_b}" | cut -d'[' -f1)"

    case "${mode}" in
        same)
            log "DEBUG" "Validating paths are on same filesystem:\n\t${path_a}\n\t${path_b}"
            if [[ "${fs_a}" != "${fs_b}" ]]; then
                die "Paths are not on same filesystem\n\t${path_a} (${fs_a})\n\t${path_b} (${fs_b})"
            fi
            ;;
        diff)
            log "DEBUG" \
                "Validating that paths are on different filesystems:\n\t${path_a}\n\t${path_b}"
            if [[ "${fs_a}" == "${fs_b}" ]]; then
                die "Paths are on same filesystem\n\t${path_a} (${fs_a})\n\t${path_b} (${fs_b})"
            fi
            ;;
        *)
            die "Usage: check_filesystem <same|diff> <path_a> <path_b>"
            ;;
    esac
}

validate_path() {
    local path fs_check="" path_fs=""
    [[ $# -eq 0 ]] && die "No path provided to validate"

    # Identify if first arg is a filesystem type instead of a path
    if [[ ! "${1}" =~ "/" ]]; then
        fs_check="${1}"
        shift
    fi

    for path in "$@"; do
        [[ ! -d "${path}" ]] && die "Path does not exist: ${path}"
        if [[ -n "${fs_check}" ]]; then
            log "DEBUG" "Validating path exists on ${fs_check} filesystem: ${path}"
            path_fs="$(stat -f -c '%T' "${path}")"
            [[ "${path_fs,,}" == "${fs_check,,}" ]] ||
                die "Path is not on ${fs_check} filesystem: ${path}"
        fi
    done
}

populated_or_afile_dirs() {
    local _dir dir_items items_count
    shopt -s dotglob nullglob
    find "${1}" -type d | while read -r _dir; do
        dir_items=("${_dir}"/*)
        items_count=${#dir_items[@]}
        if [[ ${items_count} -gt 1 ]]; then
            # Print when it's a populated directory
            echo "${_dir}"
        elif [[ ${items_count} -eq 1 && -f "${dir_items[0]}" ]]; then
            # Print when it's a directory with a file
            echo "${_dir}"
        fi
    done
    shopt -u dotglob nullglob
}

unarchive() {
    local archive="${1}" dest="${2}"

    [[ -z "${archive}" || -z "${dest}" ]] && die "No archive or destination path was provided"

    ensure_dir "${dest}"
    case "${archive}" in
        *.zip|*.ZIP)
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

is_network_metered() {
    /usr/bin/busctl get-property org.freedesktop.NetworkManager \
        /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered | cut -d' ' -f2
}

check_network_connection() {
    local max_attempts=3 sleep_time=2 attempt=1

    while (( attempt <= max_attempts )); do
        if curl --silent --head --fail "https://fedoraproject.org" >/dev/null; then
          return 0
        else
          log "DEBUG" "Network connection is not available. Waiting..."
          sleep "${sleep_time}"
          (( attempt++ ))
        fi
    done

    return 1
}

curl_fetch() { curl -fsS --retry 5 "${1}"; }

curl_get() { curl -fLsS --retry 5 -o "${1}" "${2}"; }

ensure_repo() { [[ -d "${2}" ]] || git clone --depth 1 "${1}" "${2}"; }

latest_ghpkg_url() {
    local repo="${1}" include_pattern="${2:-}" exclude_pattern="${3:-}" sha="${4:-}"
    local gh_release="https://api.github.com/repos/${repo}/releases/latest"
    local jq_filter='.assets[] | select(.name | test($inc) and (if $exc != "" then test($exc) |
                        not else true end)).browser_download_url'

    [[ -n "${JQ_FILTER:-}" ]] && jq_filter="${JQ_FILTER}"
    [[ -n "${GHPKG_VERSION:-}" ]] && gh_release="${gh_release/latest/tags}/${GHPKG_VERSION}"
    [[ ${GHPKG_PRERELEASE:-0} -eq 1 ]] && {
        gh_release="${gh_release/\/latest/}"
        jq_filter='map(select(.prerelease == true)) | first | '"${jq_filter}"
    }

    local ii response url vals=()
    for ii in {1..5}; do
        { brief_untrace; } 2>/dev/null
        response="$(curl_fetch "${gh_release}")"
        { brief_untrace; } 2>/dev/null
        url=$(jq -r --arg inc "${include_pattern}" \
                    --arg exc "${exclude_pattern}" "${jq_filter}" <<< "${response}")
        vals+=("${url}")

        if [[ "${sha:-}" == "sha" ]]; then
            jq_filter="${jq_filter%.browser_*}.digest"
            sha=$(jq -r --arg inc "${include_pattern}" \
                        --arg exc "${exclude_pattern}" "${jq_filter}" <<< "${response}")
            vals+=("${sha}")
        fi
        [[ -n "${url}" ]] && printf '%s\n' "${vals[@]}" && return 0
        sleep 0.4
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

    if [[ ${#found_execs[@]} -eq 1 ]]; then
        log "DEBUG" "Executable: ${exec_name} | Mimetype: $(file -b --mime "${found_execs[0]}")"
        ensure_dir "${bin_dir}"
        cp ${VERBOSE:+-v} -f "${found_execs[0]}" "${bin_dir}"/
        chmod ${VERBOSE:+-v} +x "${bin_dir}/${exec_name}"
    elif [[ ${#found_execs[@]} -gt 1 ]]; then
        die "More than 1 executable with same name\n$(printf '%s\n' "${found_execs[@]}")"
    else
        die "No executable found: ${exec_name}"
    fi
}

get_ghpkg() {
    local pkg_name pkg_repo pkg_regx pkg_negx="" islibexec=0
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --name)    pkg_name="${2}"; shift ;; # Set package name
            --repo)    pkg_repo="${2}"; shift ;; # GitHub repo (owner/repo)
            --regx)    pkg_regx="${2}"; shift ;; # Filter release assets by regex
            --negx)    pkg_negx="${2}"; shift ;; # Exclude assets matching by regex
            --libexec) islibexec=1 ;;            # Installs package contents into libexec
            *)         die "Unknown option: ${1}" ;;
        esac
        shift
    done
    local pkg_vals pkg_url pkg_sha pkg_archive ii
    readarray -t pkg_vals < <(latest_ghpkg_url "${pkg_repo}" "${pkg_regx}" "${pkg_negx:-musl}" "sha")
    pkg_url="${pkg_vals[0]}"
    pkg_sha="${pkg_vals[1]#*:}"
    pkg_archive="${TMP_DIR:-/tmp/get_ghpkg}/$(basename "${pkg_url}")"

    mkdir ${VERBOSE:+-v} -p "$(dirname "${pkg_archive}")"
    curl_get "${pkg_archive}" "${pkg_url}"
    if [[ -n "${pkg_sha}" && "${pkg_sha}" != "null" ]]; then
        sha256sum -c <<< "${pkg_sha}  ${pkg_archive}" ||
        for ii in {1..4}; do
            if [[ ${ii} -lt 4 ]]; then
                err "Checksum mismatch for package: ${pkg_name}"
                log "INFO" "Retrying ${ii}..."
                rm "${pkg_archive}"
                curl_get "${pkg_archive}" "${pkg_url}"
                if sha256sum -c <<< "${pkg_sha}  ${pkg_archive}"; then break
                else continue; fi
            else
                die "Max attempts reached, package checksum verification failed: ${pkg_name}"
            fi
        done
    else
        log "WARN" "Checksum skipped, package digest unavailable in repo: ${pkg_repo}"
    fi
    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    # Detect top populated directories
    readarray -t auto_fold_dir < <(populated_or_afile_dirs "${pkg_archive}.extract")

    if [[ ${islibexec} -ne 1 ]]; then
        place_executable "${auto_fold_dir[0]}" "${pkg_name}"
    else
        local libexec_dir="${LIBEXEC_DIR:-/usr/libexec}"
        log "DEBUG" "Copying contents of ${auto_fold_dir[0]} in ${libexec_dir}/${pkg_name}"
        mkdir ${VERBOSE:+-v} -p "${libexec_dir}/${pkg_name}"
        ocopy "${auto_fold_dir[0]}" "${libexec_dir}/${pkg_name}"
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
            font_url="$(latest_ghpkg_url 'ryanoasis/nerd-fonts' '.' 2>/dev/null | \
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
