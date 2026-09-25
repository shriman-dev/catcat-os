#!/usr/bin/env bash
need_root() {
    [[ ${EUID} -eq 0 ]] || die "This operation requires root privileges"
}

exit_if_root() {
    [[ ${EUID} -eq 0 ]] && die "Cannot run as root"
    [[ "${USER}" == "gdm" ]] && die "Cannot run as gdm user"
    [[ "${HOME}" =~ (/run/gdm|/var/lib/gdm) ]] && die "Cannot run as gdm user"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_container() {
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        return 0
    fi
    return 1
}

run_as_users() {
    local cmd="${1}"; shift
    local args tmp_cmd run_cmd running_user some_user_id some_user
    tmp_cmd="$(mktemp)"
    args=("$@")

    [[ -n "${cmd}" ]] || { err "Provide command"; return 1; }

    if declare -F "${cmd}" >/dev/null; then
        run_cmd="${tmp_cmd}"
        echo -e "$(declare -f "${cmd}"); ${cmd} \"\$@\"" > "${run_cmd}"
        chmod ${VERBOSE:+-v} 755 "${run_cmd}"
    elif type -f "${cmd}" >/dev/null; then
        run_cmd="${cmd}"
    else
        die "Not an executable or a shell function: ${cmd}"
    fi

    for running_user in /run/user/*; do
        some_user_id="$(basename "${running_user}")"
        some_user="$(id -un "${some_user_id}")"
        if [[ ! "${some_user}" =~ ^(root|gdm)$ ]]; then
            log "DEBUG" "Running given commancatd as user: ${some_user}"
            sudo -u "${some_user}" bash -c 'exec "$@"' _ "${run_cmd}" "${args[@]}"
        fi
    done
    rm -f "${tmp_cmd}"
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
        err "Notification failed: display-manager was not running"
    fi
}

retry_cmd() {
    local cmd max_attempts=3 sleep_time=2 attempt=0 return_value=1
    cmd=("$@")

    [[ ${#cmd[@]} -eq 0 ]] && { err "Provide command"; return 1; }

    while [[ ${attempt} -le ${max_attempts} ]]; do
        "${cmd[@]}" && return_value=0 && break
        sleep "${sleep_time}"
        attempt=$(( attempt + 1 ))
    done
    return "${return_value}"
}

cmd_test_timer() {
    local endt totaltime
    if [[ -n "${_cmd_test_timer_start}" ]]; then
        endt=$(( EPOCHSECONDS - _cmd_test_timer_start ))
        totaltime="$(printf "%02d:%02d:%02d\n" $((endt/3600)) $((endt%3600/60)) $((endt%60)))"
        echo "${totaltime}"
    fi
}

# Quiet mode handling function
_quiet_exec() {
    local cmd
    cmd=("$@")

    [[ ${#cmd[@]} -eq 0 ]] && { err "Provide command"; return 1; }

    if [[ ${QUIET} == true ]]; then
        "${cmd[@]}" >/dev/null 2>&1
    else
        "${cmd[@]}"
    fi
}


