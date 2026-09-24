#!/usr/bin/env bash
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
        FATAL) color="${red}"    ;;
        *)     return 1 ;;
    esac

    printf "%s\n"  "${bold}${datetime}${color}[${level}]${noc} ${msg}"
)

# Error handling with optional pre-exit function call
die() {
    local pre_exit_hook="${2:-}"
    [[ -n "${pre_exit_hook}" ]] && { ${pre_exit_hook} || true; }
    log "FATAL" "${1}" >&2; exit 1
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

# Checks the exit status of the last command
last_cmd_status() {
    local exit_code="${?}"
    local mode="die"
    local msg=""

    [[ ${exit_code} -eq 0 ]] && {
        #log "DEBUG" "Last command succeeded with exit code ${exit_code}"
        return 0
    }

    case "${1}" in
        err|die)
            mode="${1}"
            msg="${2:-Command failed with exit code ${exit_code}}"
            ;;
        *)
            mode="die"
            msg="${1:-Command failed with exit code ${exit_code}}"
            ;;
    esac
    "${mode}" "${msg}"
}
