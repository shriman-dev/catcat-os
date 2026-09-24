#!/usr/bin/env bash
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
            mkdir ${VERBOSE:+-v} -p -- "${_dir}" || die "Failed create directory: ${_dir}"
        fi
    done
}

check_file_presence() {
    local _file
    for _file in "$@"; do
        if [[ -f "${_file}" ]]; then
            log "DEBUG" "File exists: ${_file}"
        else
            die "File does not exist: ${_file}"
        fi
    done
}

check_dir_presence() {
    local _dir
    for _dir in "$@"; do
        if [[ -d "${_dir}" ]]; then
            log "DEBUG" "Directory exists: ${_dir}"
        else
            die "Directory does not exist: ${_dir}"
        fi
    done
}

# Checks if last modification time of file/directory is older than a specified seconds
is_older_than() {
    local target_path threshold_sec target_mtime_sec current_time_sec targett_aged_sec
    target_path="${1%/}"
    threshold_sec=${2}

    [[ -e "${target_path}" ]] || die "Does not exist: ${target_path}"
    test_int "${threshold_sec}" || die "Not an integer: ${threshold_sec}"

    target_mtime_sec=$(stat -c "%Y" "${target_path}")
    current_time_sec=${EPOCHSECONDS}
    targett_aged_sec=$(( current_time_sec - target_mtime_sec ))

    if [[ ${targett_aged_sec} -gt ${threshold_sec} ]]; then
        return 0
    else
        return 1
    fi
}

