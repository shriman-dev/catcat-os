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
    local pre_exit_hook="${2:-}"
    log "ERROR" "${1}"; [[ -n "${pre_exit_hook}" ]] && ${pre_exit_hook}; exit 1
}

err() { log "ERROR" "${1}"; return 1; }


########
## Function to generate a choice selection and return the selected choice
########
# CHOICE=$(Choice option1 option2 "option 3")
# *user selects "option 3"*
# echo "$CHOICE" will return "option 3"
function Choose (){
    CHOICE=$(ugum choose "$@")
    echo "$CHOICE"
}

########
## Function to generate a confirm dialog and return the selected choice
########
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
    COLOR="${1}"
    echo "${COLOR}" | sed -E 's/\[3([0-8]{1,1})/\[4\1/'
}

# Function to generate a clickable link, you can call this using
function Urllink (){
    URL="${1}"
    TEXT="${2}"
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

# Quiet mode handling function
_quiet_exec() {
    local cmd="$@"
    if [[ ${QUIET} == true ]]; then
        ${cmd} >/dev/null
    else
        ${cmd}
    fi
}

need_root() {
    [[ $(id -u) -eq 0 ]] || die "This operation requires root privileges"
}

exit_if_root() {
    [[ $(id -u) -eq 0 ]] && die "Cannot run as root"
    [[ $(id -un) == "gdm" ]] && die "Cannot run as gdm user"
    [[ "${HOME}" =~ (/run/gdm|/var/lib/gdm) ]] && die "Cannot run as gdm user"
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

# Check if a file is older than a specified number of seconds
is_file_older() {
    local max_age_seconds="${1}"
    local path="${2}"
    [[ $(stat -c "%Y" "${path}") -lt $(( $(date +%s) - max_age_seconds )) ]]
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

is_network_metered() {
    /usr/bin/busctl get-property org.freedesktop.NetworkManager \
        /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered | cut -d' ' -f2
}

replace_add() {
    grep -qi "${1}" ${3} && sed -i -e "s|.*${1}.*|${2}|" ${3} || sh -c "echo '${2}' >> ${3}"
}

bak_before() {
    [[ ! -e ${1}.og.bak ]] && {
        cp ${VERBOSE:+-v} -drf ${1} ${1}.og.bak || err "Backup failed for orignal ${1}"
    }
    cp ${VERBOSE:+-v} -drf ${1} ${1}.bak || err "Backup failed for ${1}"
}
