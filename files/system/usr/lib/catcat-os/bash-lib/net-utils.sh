#!/usr/bin/env bash
check_network_metered() {
    nmcli -f connection.metered connection show \
        "$(nmcli -t -f GENERAL.CONNECTION --mode tabular device show | head -n1)" | \
            grep -w 'yes'
}

check_network_connection() {
    log "DEBUG" "Checking network connectivity..."
    retry_cmd ping -c 1 -W 2 9.9.9.9 >/dev/null 2>&1 && {
        log "DEBUG" "Success: Network is online"
        return 0
    }
    log "DEBUG" "Failure: Network is offline"
    return 1
}

curl_fetch() { retry_cmd curl -fsS --retry 5 "${1}"; }

curl_get() { retry_cmd curl -fLsS --retry 5 -o "${1}" "${2}"; }

aria2_get() {
    local out_file="${1}" url="${2}"

    retry_cmd aria2c --quiet\
                     --continue=true \
                     --file-allocation=none \
                     --max-connection-per-server=16 \
                     --min-split-size=1M \
                     --split=16 \
                     --max-tries=5 \
                     --auto-file-renaming=false \
                     --allow-overwrite=true \
                     --out="$(dirname -- "${out_file}")" \
                     --dir="$(basename -- "${out_file}")"\
                     "${url}"
}

get_file() {
    if has_cmd aria2c; then
        aria2_get "$@"
    else
        curl_get "$@"
    fi
}

ensure_repo() { [[ -d "${2}" ]] || git clone --depth 1 "${1}" "${2}"; }
