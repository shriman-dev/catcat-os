#!/bin/bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

#sddm.service
services_enable() {
#fstrim.time libvirtd.service lactd.service coolercontrold.service \
#sssd-kcm.service sssd.service
    log "DEBUG" "Enabling system services"
    systemctl -f enable \
        nix.mount \
        catcat-system-setup.service \
        catcat-os-update.timer \
        catcat-system-maintenance.timer

#dualsense-catppuccin-rainbow.service
    log "DEBUG" "Enabling global services"
    systemctl --global -f enable \
        libadwaita-theme-sync.service \
        catcat-user-setup.service
    log "DEBUG" "Done."
}

#gdm.service
#setroubleshootd.service
#packagekitd.service
#low-memory-monitor.service
#thermald.service
#uresourced.service
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
    "cups-browsed.service"
    "cups.path"
    "cups.service"
    "cups.socket"
    "dconf-update.service"
    "flatpak-add-fedora-repos.service"
    "flatpak-system-update.timer"
    "fwupd.service"
    "fwupd-refresh.timer"
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
    "sshd-keygen.target"
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
    log "DEBUG" "Disabling and masking system services"
    systemctl disable ${DISABLE_SERVICES[@]}
    systemctl mask ${DISABLE_SERVICES[@]}

    log "DEBUG" "Disabling and masking global services"
    systemctl --global disable ${GLOBAL_DISABLE_SERVICES[@]}
    systemctl --global mask ${GLOBAL_DISABLE_SERVICES[@]}
    log "DEBUG" "Done."
}

if [[ $# -eq 0 ]]; then
    services_enable
    services_disable
    exit 0
fi

case "${1}" in
    enable) services_enable;;
    disable) services_disable;;
    *) echo -e "Usage: $(basename ${0}) [enable|disable]"; exit 1;;
esac
