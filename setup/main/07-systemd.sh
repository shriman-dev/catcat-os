#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

services_enable() {
#libvirtd.service cardwired.service
    log "INFO" "Enabling system services"
    systemctl -f enable \
        nix.mount \
        podman.socket \
        catcat-system-setup.service \
        catcat-os-update.timer \
        catcat-maintenance.timer \
        dmemcg-booster-system.service

#dualsense-catppuccin-rainbow.service
    log "INFO" "Enabling global services"
    systemctl --global -f enable \
        libadwaita-theme-sync.service \
        catcat-user-setup.service \
        dmemcg-booster-user.service
    log "INFO" "Enabled system services"
}

#setroubleshootd.service
#packagekitd.service
#sshd-keygen.target
#fedora-atomic-desktop-appstream-cache-refresh.service
DISABLE_SERVICES=(
    # Ublue/Bazzite
    "bazzite-flatpak-manager.service"
    "bazzite-libvirtd-setup.service"
    "flatpak-system-update.timer"
    "ntfs-nag.service"
    "tailscaled.service"
    "ublue-os-media-automount.service"
    "ublue-update.service"
    "ublue-update.timer"
    "uupd.service"
    "uupd.timer"

    # Brew
    "brew-dir-fix.service"
    "brew-setup.service"
    "brew-update.timer"
    "brew-upgrade.timer"

    # Network
    "avahi-daemon.service"
    "avahi-daemon.socket"
    "httpd.service"
    "iwd.service" # Masked to provide wider hardware support via wpa_supplicant
    "ModemManager.service"
    "NetworkManager-wait-online.service"

    # Remote Access
    ## SSH
    "sshd.service"
    "sshd.socket"
    "sshd-unix-local.socket"
    "sshd-vsock.socket"
    ## SSSD (System Security Services Daemon)
    "sssd.service"
    "sssd-kcm.service"
    "sssd-kcm.socket"
    ## RPC (Remote Procedure Call)
    "rpc-gssd.service"
    "rpc-statd-notify.service"
    "rpc-statd.service"
    "rpc_pipefs.target"
    "rpcbind.service"
    "rpcbind.socket"
    "rpcbind.target"
    "gssproxy.service"

    # Remote Storage
    ## iSCSI (Internet Small Computer Systems Interface) storage
    "iscsid.service"
    "iscsid.socket"
    "iscsiuio.service"
    "iscsiuio.socket"
    ## NFS (Network File System)
    "nfs-blkmap.service"
    "nfs-client.target"
    "nfs-idmapd.service"
    "nfs-mountd.service"
    "nfs-server.service"
    "nfs-utils.service"
    "nfsdcld.service"
    "var-lib-nfs-rpc_pipefs.mount"

    # Bootc and Ostree
    "bootc-fetch-apply-updates.timer"
    "rpm-ostree-countme.service"
    "rpm-ostree-countme.timer"
    "rpm-ostreed-automatic.timer"

    # Fedora and Flatpak
    "fedora-atomic-desktop-appstream-cache-refresh.service"
    "flatpak-add-fedora-repos.service"
    "flatpak-system-update.timer"

    # Desktop Environment
    ## Gnome
    "dconf-update.service"
    "geoclue.service"
    "localsearch-3.service"
    "localsearch-control-3.service"
    "localsearch-writeback-3.service"
    "tracker-miner-fs-3.service"
    "tracker-miner-fs-control-3.service"
    "tracker-miner-rss-3.service"
    "tracker-writeback-3.service"
    "tracker-xdg-portal-3.service"

    # Hardware and Peripherals
    "bolt.service"
    "cups-browsed.service"
    "cups.path"
    "cups.service"
    "cups.socket"
    "input-remapper.service"
    "supergfxd.service"

     # Systemd Unneeded
    "fstrim.timer"
    "systemd-homed.service"
    "systemd-homed-activate.service"
    "systemd-homed-firstboot.service"
    "systemd-nsresourced.service"
    "systemd-nsresourced.socket"
    "systemd-remount-fs.service"
)

GLOBAL_DISABLE_SERVICES=(
    "io.github.kolunmi.Bazaar.service"
    "bazzite-user-setup.service"
    "evolution-addressbook-factory.service"
    "evolution-alarm-notify.service"
    "evolution-calendar-factory.service"
    "evolution-source-registry.service"
    "evolution-user-prompter.service"
    "flatpak-user-updates.timer"
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
    systemctl -v disable "${DISABLE_SERVICES[@]}" || true
    systemctl -v mask "${DISABLE_SERVICES[@]}" || true

    log "INFO" "Disabling and masking global services"
    systemctl -v --global disable "${GLOBAL_DISABLE_SERVICES[@]}" || true
    systemctl -v --global mask "${GLOBAL_DISABLE_SERVICES[@]}" || true
    log "INFO" "Disabled system services"
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
        *) die "Usage: $(basename -- "${0}") [enable|disable]";;
    esac
fi
