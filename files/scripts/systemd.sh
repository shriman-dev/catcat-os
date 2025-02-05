#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

#sddm.service
systemctl -f enable fstrim.timer nix.mount catcat-system-setup.service auto-power-profile.service catcat-flatpak-manager.service catcat-flatpak-manager.timer libvirtd.service ublue-update.service ublue-update.timer

systemctl --global -f enable catcat-user-setup.service libadwaita-theme-sync.service

#gdm.service
systemctl disable tailscaled.service geoclue.service cups.service cups-browsed.service flatpak-system-update.timer brew-dir-fix.service brew-setup.service brew-update.service brew-upgrade.service input-remapper.service NetworkManager-wait-online.service systemd-networkd-wait-online.service tailscaled.service sshd.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service dconf-update.service flatpak-add-fedora-repos.service httpd.service rpm-ostree-countme.service rpm-ostree-countme.timer nfs-client.target remote-fs.target remote-fs-pre.target rpcbind.service nfs-idmapd.service nfs-mountd.service nfsdcld.service rpc-gssd.service rpc-statd.service rpc-statd-notify.service gssproxy.service sssd.service sssd-kcm.service

systemctl mask sshd.service geoclue.service httpd.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service rpm-ostree-countme.service rpm-ostree-countme.timer nfs-client.target remote-fs.target remote-fs-pre.target rpcbind.service nfs-idmapd.service nfs-mountd.service nfsdcld.service rpc-gssd.service rpc-statd.service rpc-statd-notify.service gssproxy.service sssd.service sssd-kcm.service

systemctl --global disable bazzite-user-setup.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service

systemctl --global mask bazzite-user-setup.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service
