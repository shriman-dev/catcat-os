#!/usr/bin/bash
source /usr/lib/tuned/functions

start() {
    if [[ "$(/usr/bin/systemctl is-enabled scx_loader.service)" == "enabled" ]]; then
        /usr/bin/scxctl switch -m auto
    fi
    return 0
}

stop() {
    return 0
}

process "$@"
