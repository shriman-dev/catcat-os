#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

# Cleanup is not required when rebuilding image of current project
log "INFO" "Cleaning up system"

if [[ -d /usr/share/ublue-os ]]; then
    log "INFO" "Removing ublue/bazzite defaults"
    rm -rvf /home/linuxbrew \
            /usr/share/ublue-os/homebrew \
            /usr/share/ublue-os/dconfs \
            /usr/share/ublue-os/flatpak-blocklist \
            /usr/share/ublue-os/motd
    rm -vf /usr/bin/bbrew-helper \
           /usr/lib/systemd/system/brew-dir-fix.service \
           /usr/lib/systemd/system/brew-setup.service \
           /usr/lib/systemd/system/brew-update.timer \
           /usr/lib/systemd/system/brew-update.service \
           /usr/lib/systemd/system/brew-upgrade.timer \
           /usr/lib/systemd/system/brew-upgrade.service \
           /usr/lib/systemd/system-preset/01-homebrew.preset \
           /usr/lib/tmpfiles.d/homebrew.conf \
           /usr/share/applications/bbrew.desktop \
           /usr/share/homebrew.tar.zst \
           /usr/share/fish/vendor_conf.d/brew.fish \
           /usr/share/ublue-os/firstboot/yafti.yml \
           /usr/libexec/ntfs_exfat_monitor_script \
           /usr/libexec/bazzite-user-setup \
           /usr/libexec/topgrade/mozilla-gnome-theme-update \
           /usr/share/applications/bazzite-steam-bpm.desktop \
           /usr/share/applications/gnome-ssh-askpass.desktop \
           /usr/share/fish/vendor_conf.d/bazzite-neofetch.fish \
           /usr/share/fish/vendor_conf.d/ublue-brew.fish \
           /usr/share/fish/vendor_conf.d/nano-default-editor.fish \
           /usr/share/fish/functions/fish_greeting.fish \
           /usr/share/ublue-os/bazaar/blocklist.txt \
           /etc/profile.d/askpass.sh \
           /etc/profile.d/bazzite-neofetch.sh \
           /etc/profile.d/brew.sh \
           /etc/profile.d/brew-bash-completion.sh \
           /etc/profile.d/user-motd.sh
fi

cachy="${BUILD_CACHE_DIR}/conf_repos/cachyos_settings"
if [[ -d "${cachy}" ]]; then
    log "INFO" "Removing unneeded configurations in cachyos settings"
    rm -rvf "${cachy}"/.git \
            "${cachy}"/etc/debuginfod \
            "${cachy}"/usr/lib/NetworkManager \
            "${cachy}"/usr/lib/sysctl.d \
            "${cachy}"/usr/lib/systemd/journald.conf.d \
            "${cachy}"/usr/lib/systemd/timesyncd.conf.d \
            "${cachy}"/usr/share/glib-* \
            "${cachy}"/usr/share/icons
    rm -vf "${cachy}"/*.md \
           "${cachy}"/usr/bin/cachyos-bugreport.sh \
           "${cachy}"/usr/bin/game-performance \
           "${cachy}"/usr/bin/paste-cachyos \
           "${cachy}"/usr/bin/sbctl-batch-sign \
           "${cachy}"/usr/bin/topmem \
           "${cachy}"/usr/lib/udev/rules.d/60-ioschedulers.rules
fi
unset cachy

log "INFO" "Removing dconf and skel defaults"
rm -rvf /etc/skel/* \
        /etc/skel/.* \
        /etc/dconf/db/distro.d/* \
        /usr/etc/skel/* \
        /usr/etc/skel/.* \
        /usr/etc/dconf/db/distro.d/*

log "INFO" "Removing unneeded profile.d scripts, localsearchdb miner, xdg autostart files and rpm repos"
rm -vf /etc/profile.d/toolbox.sh \
       /usr/lib/systemd/user/tracker*3.service \
       /usr/lib/systemd/user/localsearch*3.service \
       /etc/xdg/autostart/ibus-mozc-launch-xwayland.desktop \
       /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
       /etc/xdg/autostart/org.gnome.Software.desktop \
       /etc/xdg/autostart/nvidia-settings-load.desktop \
       /etc/xdg/autostart/localsearch*3.desktop \
       /etc/xdg/autostart/tracker*3.desktop \
       /etc/xdg/autostart/steam.desktop \
       /etc/yum.repos.d/charm.repo \
       /etc/yum.repos.d/google-chrome.repo \
       /etc/yum.repos.d/tailscale.repo

log "INFO" "Cleanup done"
