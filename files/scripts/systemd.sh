#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"

#sddm.service
systemctl -f enable fstrim.timer nix.mount catcat-system-setup.service auto-power-profile.service catcat-flatpak-manager.service

systemctl --global -f enable catcat-user-setup.service libadwaita-theme-sync.service

#gdm.service
systemctl disable cups.service flatpak-system-update.timer brew-dir-fix.service brew-setup.service brew-update.service brew-upgrade.service input-remapper.service NetworkManager-wait-online.service systemd-networkd-wait-online.service tailscaled.service sshd.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service dconf-update.service ublue-update.service ublue-update.timer

systemctl mask sshd.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service

systemctl --global disable bazzite-user-setup.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service

systemctl --global mask bazzite-user-setup.service tracker-miner-fs-3.servicee tracker-miner-fs-control-3.service tracker-miner-rss-3.service tracker-writeback-3.service tracker-xdg-portal-3.service
