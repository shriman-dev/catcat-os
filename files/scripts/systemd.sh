#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

#sddm.service
services_enable() {
  command -v hhdctl || systemctl -f enable auto-power-profile.service
  command -v hhdctl || systemctl -f enable catcat-os-update.timer
  systemctl -f enable \
    fstrim.timer \
    nix.mount \
    libvirtd.service \
    catcat-system-setup.service \
    catcat-system-maintenance.timer \
    catcat-flatpak-manager.timer

  systemctl --global -f enable \
    libadwaita-theme-sync.service \
    dualsense-catppuccin-rainbow.service \
    catcat-user-setup.service
}

#gdm.service
#setroubleshootd.service
#packagekitd.service
services_disable() {
  systemctl disable \
    bazzite-flatpak-manager.service \
    brew-dir-fix.service \
    brew-setup.service \
    brew-update.service \
    brew-upgrade.service \
    cups-browsed.service \
    cups.service \
    dconf-update.service \
    flatpak-add-fedora-repos.service \
    flatpak-system-update.timer \
    geoclue.service \
    gssproxy.service \
    httpd.service \
    input-remapper.service \
    nfs-client.target \
    nfs-idmapd.service \
    nfs-mountd.service \
    nfsdcld.service \
    NetworkManager-wait-online.service \
    rpc-gssd.service \
    rpc-statd-notify.service \
    rpc-statd.service \
    rpcbind.service \
    rpm-ostree-countme.service \
    rpm-ostree-countme.timer \
    sshd.service \
    sssd-kcm.service \
    sssd.service \
    systemd-remount-fs.service \
    tailscaled.service \
    tracker-miner-fs-3.service \
    tracker-miner-fs-control-3.service \
    tracker-miner-rss-3.service \
    tracker-writeback-3.service \
    tracker-xdg-portal-3.service \
    ublue-update.service \
    ublue-update.timer \
    uupd.service \
    uupd.timer

  systemctl mask \
    geoclue.service \
    gssproxy.service \
    httpd.service \
    nfs-client.target \
    nfs-idmapd.service \
    nfs-mountd.service \
    nfsdcld.service \
    remote-fs-pre.target \
    remote-fs.target \
    rpm-ostree-countme.service \
    rpm-ostree-countme.timer \
    rpc-gssd.service \
    rpc-statd-notify.service \
    rpc-statd.service \
    rpcbind.service \
    sshd.service \
    sssd-kcm.service \
    sssd.service \
    tracker-miner-fs-3.service \
    tracker-miner-fs-control-3.service \
    tracker-miner-rss-3.service \
    tracker-writeback-3.service \
    tracker-xdg-portal-3.service \
    ublue-update.service \
    ublue-update.timer \
    uupd.service \
    uupd.timer

  systemctl --global disable \
    bazzite-user-setup.service \
    tracker-miner-fs-3.service \
    tracker-miner-fs-control-3.service \
    tracker-miner-rss-3.service \
    tracker-writeback-3.service \
    tracker-xdg-portal-3.service

  systemctl --global mask \
    bazzite-user-setup.service \
    tracker-miner-fs-3.service \
    tracker-miner-fs-control-3.service \
    tracker-miner-rss-3.service \
    tracker-writeback-3.service \
    tracker-xdg-portal-3.service
}

if [[ $# -eq 0 ]]; then
  services_enable
  services_disable
  exit 0
fi

case "$1" in
  enable) services_enable;;
  disable) services_disable;;
  *) echo -e "Usage: $0 [enable|disable]"; exit 1;;
esac
