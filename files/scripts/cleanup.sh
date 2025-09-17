#!/usr/bin/env bash
set -oue pipefail
echo -e "\n$0\n"

#rm -vf /usr/share/pixmaps/fedora*
#rm -vf /usr/share/pixmaps/bootloader/fedora.icns

###

# disable ibus (causes input lag)
#chmod 000 /usr/bin/ibus
#chmod 000 /usr/bin/ibus-daemon
#chmod 000 /usr/bin/ibus-setup

chmod 000 /usr/libexec/evolution-source-registry
chmod 000 /usr/libexec/evolution-addressbook-factory
chmod 000 /usr/libexec/evolution-calendar-factory
chmod 000 /usr/libexec/evolution-data-server/evolution-alarm-notify

chmod 000 /usr/libexec/goa-daemon
chmod 000 /usr/libexec/goa-identity-service

rm -rf /home/linuxbrew
rm -rf /usr/share/ublue-os/homebrew
rm -vf /usr/lib/systemd/system/brew-dir-fix.service
rm -vf /usr/lib/systemd/system/brew-setup.service
rm -vf /usr/lib/systemd/system/brew-update.service
rm -vf /usr/lib/systemd/system/brew-upgrade.service

rm -vf /usr/lib/systemd/user/tracker-miner-fs-3.service
rm -vf /usr/lib/systemd/user/tracker-miner-fs-control-3.service
rm -vf /usr/lib/systemd/user/tracker-miner-rss-3.service
rm -vf /usr/lib/systemd/user/tracker-writeback-3.service
rm -vf /usr/lib/systemd/user/tracker-xdg-portal-3.service

[[ ! -d /etc/catcat-os ]] && rm -rvf /usr/etc/skel/*
[[ ! -d /etc/catcat-os ]] && rm -rvf /usr/share/glib-2.0/schemas/zz*
[[ ! -d /etc/catcat-os ]] && rm -vf  /usr/share/ublue-os/firstboot/yafti.yml
rm -vf  /usr/libexec/topgrade/mozilla-gnome-theme-update
rm -vf  /usr/share/applications/bazzite-steam-bpm.desktop
rm -vf  /usr/share/applications/gnome-ssh-askpass.desktop
rm -vf  /usr/share/fish/vendor_conf.d/bazzite-neofetch.fish
rm -vf  /usr/share/fish/vendor_conf.d/brew.fish
rm -vf  /usr/share/fish/vendor_conf.d/nano-default-editor.fish
rm -vf  /usr/share/fish/functions/fish_greeting.fish
rm -rvf /usr/share/ublue-os/bazaar/blocklist.txt
rm -rvf /usr/share/ublue-os/dconfs
rm -rvf /usr/share/ublue-os/motd

[[ ! -d /etc/catcat-os ]] && rm -rvf /etc/skel/*
[[ ! -d /etc/catcat-os ]] && rm -rvf /etc/dconf/db/distro.d/*
rm -vf  /etc/profile.d/askpass.sh
rm -vf  /etc/profile.d/bazzite-neofetch.sh
rm -vf  /etc/profile.d/brew.sh
rm -vf  /etc/profile.d/user-motd.sh

rm -vf  /etc/xdg/autostart/ibus-mozc-launch-xwayland.desktop
rm -vf  /etc/xdg/autostart/org.gnome.Software.desktop
rm -vf  /etc/xdg/autostart/nvidia-settings-load.desktop
rm -vf  /etc/xdg/autostart/tracker-miner-fs-3.desktop
rm -vf  /etc/xdg/autostart/tracker-miner-rss-3.desktop
rm -vf  /etc/xdg/autostart/steam.desktop
rm -vf  /usr/etc/xdg/autostart/org.gnome.Software.desktop
rm -vf /etc/yum.repos.d/google-chrome.repo
