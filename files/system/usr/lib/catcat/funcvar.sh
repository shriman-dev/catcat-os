#!/usr/bin/bash
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

QUIET=false
VERBOSE=2

# Logging with optional verbose output
log() {
    local color level="${1}" msg="${@:2}"
    local datetime="$([[ ${VERBOSE} -ge 2 ]] && date '+[%Y-%m-%d %H:%M:%S] ')"

    case "${level^^}" in
        "DEBUG") color=${cyan}; [[ ${QUIET} == false && ${VERBOSE} -eq 2 ]] || return ;;
        "INFO")  color=${green}; [[ ${QUIET} == false ]] || return ;;
        "WARN")  color=${yellow}; [[ ${QUIET} == false ]] || return  ;;
        "ERROR") color=${red} ;;
    esac

    echo -e "${bold}${datetime}${color}[${level^^}]${noc} ${msg}"
}

# Error handling with optional pre-exit function call
die() {
    local pre_exit_hook="${2}"
    log "ERROR" "${1}"; [[ -n "${pre_exit_hook}" ]] && ${pre_exit_hook}; exit 1
}

err() { log "ERROR" "${1}"; return 1; }

## Function to generate a choice selection and return the selected choice
# CHOICE=$(Choice option1 option2 "option 3")
# *user selects "option 3"*
# echo "$CHOICE" will return "option 3"
function Choose (){
    local CHOICE=$(ugum choose "$@")
    echo "$CHOICE"
}

## Function to generate a confirm dialog and return the selected choice
# CHOICE=$(Confirm "Are you sure you want to do this?")
# *user selects "No"*
# echo "$CHOICE" will return "1"
# 0 = Yes
# 1 = No
function Confirm (){
    ugum confirm "$@"
    echo $?
}

# Function to generate background color from foreground color
# option 38 (foreground) which can be flipped to 48 (background)
# NOTE: doublequote the color or future calls to bg will error out!
# option 38 (foreground) which can be flipped to 48 (background)
# bgblue=$(Bg "$blue")
# echo "${bgblue}text now has blue background${normal} this text has no background color"
function Bg (){
    local COLOR="${1}"
    echo "${COLOR}" | sed -E 's/\[3([0-8]{1,1})/\[4\1/'
}

# Function to generate a clickable link, you can call this using
function Urllink (){
    local URL="${1}"
    local TEXT="${2}"
    # Generate a clickable hyperlink
    printf "\033]8;;%s\033\\%s\033]8;;\033\\" "${URL}" "${TEXT}${n}"
}

# Function to generates a centered text header with customizable padding character, width, and symmetrical padding
symmetric_heading() {
    local text="${1}" padding_char="${2:-#}" output_width=${3:-75}
    local padding_length=$(( (output_width - ${#text} - 2) / 2 ))
    local left_padding=$(printf "%*s" ${padding_length} | tr ' ' "${padding_char}")
    local right_padding=$(printf "%*s" ${padding_length} | tr ' ' "${padding_char}")

    if (( ${#text} >= output_width - 3 )); then
        err "Text is too long for the given output width. Increase value of output width."
        return 1
    fi
    # Adjust for odd-length texts
    if (( (output_width - ${#text} - 2) % 2 != 0 )); then
        right_padding+="${padding_char}"
    fi

    printf "%s %s %s\n" "${left_padding}" "${text}" "${right_padding}"
}

# Same as above but with upper and lower borders using given character
enclosed_heading() {
    local text="${1}" padding_char="${2:-#}" output_width=${3:-75}
    local border=$(printf "%*s" ${output_width} | tr ' ' "${padding_char}")

    echo "${border}"
    symmetric_heading "${text}" "${padding_char}" ${output_width}
    echo "${border}"
}

need_root() {
    [[ $(id -u) -eq 0 ]] || die "This operation requires root privileges"
}

exit_if_root() {
    [[ $(id -u) -eq 0 ]] && die "Cannot run as root"
    [[ $(id -un) == "gdm" ]] && die "Cannot run as gdm user"
    [[ "${HOME}" =~ (/run/gdm|/var/lib/gdm) ]] && die "Cannot run as gdm user"
}

# Quiet mode handling function
_quiet_exec() {
    local cmd="$@"
    if [[ ${QUIET} == true ]]; then
        ${cmd} >/dev/null
    else
        ${cmd}
    fi
}

run_as_users() {
    local running_user
    for running_user in /run/user/*; do
        local some_user_id=$(basename "${running_user}")
        local some_user="$(id -un "${some_user_id}")"
        if [[ ! "${some_user}" =~ ^(root|gdm)$ ]]; then
            log "DEBUG" "Running given command as user: ${some_user}"
            sudo -u "${some_user}"  bash -c "$(declare -f $@); $@"
        fi
    done
}

notify_users() {
    local running_user
    if systemctl is-active display-manager; then
        for running_user in /run/user/*; do
            local some_user_id=$(basename "${running_user}")
            local some_user="$(id -un "${some_user_id}")"
            if [[ ! "${some_user}" =~ ^(root|gdm)$ ]]; then
                log "DEBUG" "Sending notification to user: ${some_user}"
                sudo -u "${some_user}" \
                    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"${some_user_id}"/bus \
                    notify-send -i "${1}" -a "${2}" "${3}" "${4}"
            fi
        done
    else
        err "Notification failed: display-manager was not running."
    fi
}

bak_before() {
    if [[ ! -e ${1}.og.bak ]]; then
        cp ${VERBOSE:+-v} -drf ${1} ${1}.og.bak || err "Backup failed for orignal ${1}"
    fi
    cp ${VERBOSE:+-v} -drf ${1} ${1}.bak || err "Backup failed for ${1}"
}

populated_or_afile_dirs() {
    find "${1}" -type d -exec bash -c \
    '[[ $(ls -A "{}" | wc -l) -gt 1 || $(ls -Ap "{}" | grep -Ev '/$' | wc -l) -eq 1 ]] &&
            echo "{}"' \;
}

# Check if a file is older than a specified number of seconds
is_file_older() {
    local max_age_seconds="${1}"
    local path="${2}"
    [[ $(stat -c "%Y" "${path}") -lt $(( $(date +%s) - max_age_seconds )) ]]
}

replace_add() {
    grep -qi "${1}" ${3} && sed -i -e "s|.*${1}.*|${2}|" ${3} || sh -c "echo '${2}' >> ${3}"
}

one_filesystem() {
    [[ $# -eq 2 ]] || die "Specify two paths to check filesystem"
    [[ $(stat -L -c %d ${1}) -eq $(stat -L -c %d ${2}) ]]
}

validate_path() {
    local path fs_check
    [[ $# -eq 0 ]] && die "No path provided to validate"

    if [[ ! "${1}" =~ "/" ]]; then
        local fs_check="${1}"
        shift
    fi

    for path in "$@"; do
        [[ ! -d "${path}" ]] && die "Path does not exist: ${path}"
        if [[ -n "${fs_check}" ]]; then
            log "DEBUG" "Validating path exists on ${fs_check} filesystem: ${path}"
            local path_fs="$(stat -f -c '%T' ${path})"
            [[ "${path_fs,,}" == "${fs_check,,}" ]] ||
                die "Path is not on ${fs_check} filesystem: ${path}"
        fi
    done
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
          sleep ${sleep_time}
          (( attempt++ ))
        fi
    done

    return 1
}

curl_fetch() { curl -fsS --retry 5 "${1}"; }

curl_get() { curl -fLsS --retry 5 "${2}" -o "${1}"; }

latest_ghpkg_url() {
    local repo="${1}"
    local include_pattern="${2}"
    local exclude_patterns="${3:-musl}"
    local gh_release_api="https://api.github.com/repos/${repo}/releases/${4:-latest}"

    curl_fetch "${gh_release_api}" | \
        jq -r --arg include_pattern "${include_pattern}" \
              --arg exclude_patterns "${exclude_patterns}" \
            '.assets[] |
                select(.name | test($include_pattern) and
                    (if $exclude_patterns != "" then test($exclude_patterns) | not else true end)
                ).browser_download_url'
}

latest_ghtar_url() {
    local repo="${1}"
    local gh_release_api="https://api.github.com/repos/${repo}/releases/${2:-latest}"

    curl_fetch "${gh_release_api}" | jq -r '.tarball_url'
}

unarchive() {
    local archive="${1}" dest="${2}"
    [[ ! $# -eq 2 ]] && die "Specify paths to archive and destination"

    [[ ! -d "${dest}" ]] && mkdir ${VERBOSE:+-v} -p "${dest}"

    case "${archive}" in
        *.zip|*.ZIP)
            { log "DEBUG" "Extracting ZIP archive in: ${dest}"; } 2>/dev/null
            unzip "${archive}" -d "${dest}"
            ;;
        *.7z)
            { log "DEBUG" "Extracting 7Z archive in: ${dest}"; } 2>/dev/null
            7z x -o"${dest}" "${archive}"
            ;;
        *.rar)
            { log "DEBUG" "Extracting RAR archive in: ${dest}"; } 2>/dev/null
            cd "${dest}"
            unrar x "${archive}"
            cd -
            ;;
        *.tar.*|*.tar|*.tbz|*.tbz2|*.tgz|*.tlz|*.txz|*.tzst)
            { log "DEBUG" "Extracting TAR archive in: ${dest}"; } 2>/dev/null
            tar ${VERBOSE:+-v} -xf "${archive}" -C "${dest}"
            ;;
        *)
            die "Unknown archive file: ${archive}"
            ;;
    esac
}

place_executable() {
    local exec_types="(application|text)/x-(.*executable|elf|.*script|.*python|perl|ruby)"
    local found_executables=($(find "${1}" -type f -exec file --mime '{}' \; | \
                                    grep -E "${exec_types}" | cut -d: -f1 | grep -E "/${2}\$"))

    if [[ ${#found_executables[@]} -eq 1 ]]; then
        log "DEBUG" "Executable: ${2} | Mimetype: $(file -b --mime ${found_executables[0]})"
        cp -vf "${found_executables[0]}" "${USRBIN}"/
        chmod -v +x "${USRBIN}/${2}"
    elif [[ ${#found_executables[@]} -gt 1 ]]; then
        die "More than 1 executable with same name\n$(printf '%s\n' ${found_executables[@]})"
    else
        die "No executable found: ${2}"
    fi
}

get_ghpkg() {
    local pkg_name pkg_repo pkg_regx pkg_negx="" islibexec=""
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --name)    pkg_name="${2}"; shift ;;
            --repo)    pkg_repo="${2}"; shift ;;
            --regx)    pkg_regx="${2}"; shift ;;
            --negx)    pkg_negx="${2}"; shift ;; # exclusion regx
            --libexec) islibexec=1 ;;
            *)         die "Unknown option: ${1}" ;;
        esac
        shift
    done
    local latest_pkg_url="$(latest_ghpkg_url ${pkg_repo} ${pkg_regx} ${pkg_negx})"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "$(dirname ${pkg_archive})"
    curl_get "${pkg_archive}" "${latest_pkg_url}"
    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    auto_fold_dir=($(populated_or_afile_dirs "${pkg_archive}.extract"))

    if [[ -z ${islibexec} ]]; then
        place_executable "${auto_fold_dir[0]}" "${pkg_name}"
    elif [[ -n ${islibexec} ]]; then
        log "DEBUG" "Copying contents of ${auto_fold_dir[0]} in ${USRLIBEXEC}/${pkg_name}"
        mkdir -vp "${USRLIBEXEC}/${pkg_name}"
        cp -dvf "${auto_fold_dir[0]}"/* "${USRLIBEXEC}/${pkg_name}"/
    fi
}

get_ghraw() {
    local destfile="" dest_dir="" repo_raw="" repo_dir="" ffile
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --dstf)  destfile="${2}"; shift 2 ;;
            --dstd)  dest_dir="${2}"; shift 2 ;;
            --repo)  repo_raw="${2}"; shift 2 ;;
            --repod) repo_dir="${2}"; shift 2 ;;
            -f|--flist) shift; break ;; # file or list of files to fetch
            *)       die "Unknown option: ${1}" ;;
        esac
    done
    local gh_api="https://api.github.com/repos/${repo_raw}"
    local branch="$(curl_fetch ${gh_api} | jq -r '.default_branch')"
    local raw_url="https://raw.githubusercontent.com/${repo_raw}/refs/heads/${branch}"

    [[ -n "${dest_dir}" && ! -d "${dest_dir}" ]] && mkdir -vp "${dest_dir}"
    for ffile in "$@"; do
        local dest_path="${dest_dir}/${ffile}"
        [[ -n "${destfile}" ]] && dest_path="${destfile}"
        curl_get "${dest_path}" "${raw_url}/${repo_dir:+${repo_dir}/}${ffile}"
    done
}
