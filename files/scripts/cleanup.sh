#!/usr/bin/env bash

set -oue pipefail

#rm -vf /usr/share/pixmaps/fedora*
#rm -vf /usr/share/pixmaps/bootloader/fedora.icns

# disable ibus (causes input lag)
chmod 000 /usr/bin/ibus
chmod 000 /usr/bin/ibus-daemon
chmod 000 /usr/bin/ibus-setup

chmod 000 /usr/libexec/evolution-source-registry
chmod 000 /usr/libexec/evolution-addressbook-factory
chmod 000 /usr/libexec/evolution-calendar-factory
chmod 000 /usr/libexec/evolution-data-server/evolution-alarm-notify

chmod 000 /usr/libexec/goa-daemon 
chmod 000 /usr/libexec/goa-identity-service 




systemctl disable brew-dir-fix.service brew-setup.service brew-update.service \
                  brew-upgrade.service


rm -rf /home/linuxbrew
rm -rf /usr/share/ublue-os/homebrew
rm -vf /usr/lib/systemd/system/brew-dir-fix.service
rm -vf /usr/lib/systemd/system/brew-setup.service
rm -vf /usr/lib/systemd/system/brew-update.service
rm -vf /usr/lib/systemd/system/brew-upgrade.service

systemctl disable input-remapper.service NetworkManager-wait-online.service \
                  systemd-networkd-wait-online.service tailscaled.service \
                  setroubleshootd.service cups.service ublue-update.service

systemctl  disable sshd.service
systemctl --global mask sshd.service

systemctl --global mask tracker-miner-fs-3.servicee \
                        tracker-miner-fs-control-3.service \
                        tracker-miner-rss-3.service tracker-writeback-3.service \
                        tracker-xdg-portal-3.service

rm -vf /usr/lib/systemd/user/tracker-miner-fs-3.service
rm -vf /usr/lib/systemd/user/tracker-miner-fs-control-3.service
rm -vf /usr/lib/systemd/user/tracker-miner-rss-3.service
rm -vf /usr/lib/systemd/user/tracker-writeback-3.service
rm -vf /usr/lib/systemd/user/tracker-xdg-portal-3.service

rm -rvf /etc/dconf/db/distro.d/*
rm -vf /etc/xdg/autostart/ibus-mozc-launch-xwayland.desktop
rm -vf /etc/xdg/autostart/nvidia-settings-load.desktop
rm -vf /etc/xdg/autostart/org.gnome.Software.desktop
rm -vf /etc/xdg/autostart/tracker-miner-fs-3.desktop
rm -vf /etc/xdg/autostart/tracker-miner-rss-3.desktop
rm -rvf /etc/skel/*
rm -rvf /usr/etc/skel/*

rm -rvf /usr/share/glib-2.0/schemas/zz*
rm -vf /usr/share/fish/vendor_conf.d/nano-default-editor.fish
rm -vf /usr/share/fish/vendor_conf.d/bazzite-neofetch.fish
rm -vf /usr/share/fish/functions/fish_greeting.fish
rm -vf /usr/share/applications/gnome-ssh-askpass.desktop
rm -vf /usr/share/applications/bazzite-steam-bpm.desktop
rm -vf /usr/libexec/topgrade/mozilla-gnome-theme-update

