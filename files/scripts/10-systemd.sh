#!/usr/bin/env bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

#sddm.service#gdm.service
services_enable() {
#libvirtd.service
    log "INFO" "Enabling system services"
    systemctl -f enable \
        nix.mount \
        catcat-system-setup.service \
        catcat-os-update.timer \
        catcat-maintenance.timer

#dualsense-catppuccin-rainbow.service
    log "INFO" "Enabling global services"
    systemctl --global -f enable \
        libadwaita-theme-sync.service \
        catcat-user-setup.service
    log "INFO" "Done."
}

#setroubleshootd.service
#packagekitd.service
#sshd-keygen.target
DISABLE_SERVICES=(
    "avahi-daemon.service"
    "avahi-daemon.socket"
    "bazzite-flatpak-manager.service"
    "bazzite-libvirtd-setup.service"
    "brew-dir-fix.service"
    "brew-setup.service"
    "brew-update.service"
    "brew-upgrade.service"
    "bolt.service"
    "bootc-fetch-apply-updates.timer"
    "cups-browsed.service"
    "cups.path"
    "cups.service"
    "cups.socket"
    "dconf-update.service"
    "flatpak-add-fedora-repos.service"
    "flatpak-system-update.timer"
    "fstrim.timer"
    "geoclue.service"
    "gssproxy.service"
    "httpd.service"
    "input-remapper.service"
    "localsearch-3.service"
    "localsearch-control-3.service"
    "localsearch-writeback-3.service"
    "ModemManager.service"
    "NetworkManager-wait-online.service"
    "nfs-blkmap.service"
    "nfs-client.target"
    "nfs-idmapd.service"
    "nfs-mountd.service"
    "nfsdcld.service"
    "rpc-gssd.service"
    "rpc-statd-notify.service"
    "rpc-statd.service"
    "rpc_pipefs.target"
    "rpcbind.service"
    "rpcbind.socket"
    "rpcbind.target"
    "rpm-ostree-countme.service"
    "rpm-ostree-countme.timer"
    "rpm-ostreed-automatic.timer"
    "sshd.service"
    "sshd.socket"
    "sshd-unix-local.socket"
    "tailscaled.service"
    "tracker-miner-fs-3.service"
    "tracker-miner-fs-control-3.service"
    "tracker-miner-rss-3.service"
    "tracker-writeback-3.service"
    "tracker-xdg-portal-3.service"
    "ublue-os-media-automount.service"
    "ublue-update.service"
    "ublue-update.timer"
    "uupd.service"
    "uupd.timer"
)

GLOBAL_DISABLE_SERVICES=(
    "io.github.kolunmi.Bazaar.service"
    "bazzite-user-setup.service"
    "evolution-addressbook-factory.service"
    "evolution-alarm-notify.service"
    "evolution-calendar-factory.service"
    "evolution-source-registry.service"
    "evolution-user-prompter.service"
    "localsearch-3.service"
    "localsearch-control-3.service"
    "localsearch-writeback-3.service"
    "tracker-miner-fs-3.service"
    "tracker-miner-fs-control-3.service"
    "tracker-miner-rss-3.service"
    "tracker-writeback-3.service"
    "tracker-xdg-portal-3.service"
)

services_disable() {
    log "INFO" "Disabling and masking system services"
    systemctl disable ${DISABLE_SERVICES[@]}
    systemctl mask ${DISABLE_SERVICES[@]}

    log "INFO" "Disabling and masking global services"
    systemctl --global disable ${GLOBAL_DISABLE_SERVICES[@]}
    systemctl --global mask ${GLOBAL_DISABLE_SERVICES[@]}
    log "INFO" "Done."
}

if [[ $# -eq 0 ]]; then
    services_enable
    services_disable
    exit 0
fi

if [[ $# -gt 0 ]]; then
    case "${1}" in
        enable) services_enable;;
        disable) services_disable;;
        *) die "Usage: $(basename ${0}) [enable|disable]";;
    esac
fi
