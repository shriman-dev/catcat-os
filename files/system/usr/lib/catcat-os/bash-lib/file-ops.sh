#!/usr/bin/env bash
bak_before() {
    if [[ -e "${1}" ]]; then
        if [[ ! -e "${1}.og.bak" ]]; then
            cp ${VERBOSE:+-v} -drf -- "${1}" "${1}.og.bak" || err "Backup failed for orignal ${1}"
        fi
        cp ${VERBOSE:+-v} -drf -- "${1}" "${1}.bak" || err "Backup failed for ${1}"
    fi
}

bakrestore() {
    if [[ -e "${1}.bak" ]]; then
        mv ${VERBOSE:+-v} -- "${1}.bak" "${1}"
    else
        mv ${VERBOSE:+-v} -- "${1}" "${1}.bak"
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

    if [[ ! -d "${src}" ]]; then
        log "WARN" "Source does not exists: ${src}"
        return 0
    fi

    ensure_dir "${dst}"
    tar -C "${src}" "${excludes[@]}" -cf - . | \
    tar "${verbose}" \
        --touch \
        --no-same-owner \
        --no-same-permissions \
        -C "${dst}" -xf -
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
