#!/usr/bin/bash
source /usr/lib/tuned/functions

start() {
    [[ ${USB_AUTOSUSPEND:-} -eq 1 ]] && enable_usb_autosuspend
    if [[ "$(/usr/bin/systemctl is-enabled scx_loader.service)" == "enabled" ]]; then
        /usr/bin/scxctl switch -m powersave
    fi
    enable_wifi_powersave
    return 0
}

stop() {
    [[ ${USB_AUTOSUSPEND:-} -eq 1 ]] && disable_usb_autosuspend
    disable_wifi_powersave
    return 0
}

process "$@"
