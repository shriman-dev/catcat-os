#!/usr/bin/env bash
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
    local path fs_check="" actual_fs=""
    [[ $# -eq 0 ]] && die "No path provided to validate"

    # Identify if first arg is a filesystem type instead of a path
    [[ "$1" != */* ]] && fs_check="${1}" && shift

    for path in "$@"; do
        [[ ! -d "${path}" ]] && die "Path does not exist: ${path}"
        if [[ -n "${fs_check}" ]]; then
            log "DEBUG" "Validating path exists on ${fs_check} filesystem: ${path}"
            actual_fs="$(stat -f -c '%T' "${path}")"
            [[ "${actual_fs,,}" == "${fs_check,,}" ]] ||
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
