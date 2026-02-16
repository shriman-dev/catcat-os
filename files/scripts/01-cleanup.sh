#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

# No need to run cleanup when rebuilding image of current project
if [[ ${REBUILDING_IMAGE} -ne 1 ]]; then
    log "INFO" "Cleaning up system"

    if [[ -d /usr/share/ublue-os ]]; then
        log "INFO" "Removing homebrew"
        rm -rf /home/linuxbrew
        rm -vf /usr/bin/bbrew-helper
        rm -vf /usr/lib/systemd/system/brew-dir-fix.service
        rm -vf /usr/lib/systemd/system/brew-setup.service
        rm -vf /usr/lib/systemd/system/brew-update.timer
        rm -vf /usr/lib/systemd/system/brew-update.service
        rm -vf /usr/lib/systemd/system/brew-upgrade.timer
        rm -vf /usr/lib/systemd/system/brew-upgrade.service
        rm -vf /usr/lib/systemd/system-preset/01-homebrew.preset
        rm -vf /usr/lib/tmpfiles.d/homebrew.conf
        rm -vf /usr/share/applications/bbrew.desktop
        rm -vf /usr/share/homebrew.tar.zst
        rm -vf /usr/share/fish/vendor_conf.d/brew.fish
        rm -rf /usr/share/ublue-os/homebrew

        log "INFO" "Removing ublue/bazzite defaults"
        rm -rvf /usr/share/glib-2.0/schemas/zz*
        rm -vf  /usr/share/ublue-os/firstboot/yafti.yml
        rm -vf  /usr/libexec/ntfs_exfat_monitor_script
        rm -vf  /usr/libexec/bazzite-user-setup
        rm -vf  /usr/libexec/topgrade/mozilla-gnome-theme-update
        rm -vf  /usr/share/applications/bazzite-steam-bpm.desktop
        rm -vf  /usr/share/applications/gnome-ssh-askpass.desktop
        rm -vf  /usr/share/fish/vendor_conf.d/bazzite-neofetch.fish
        rm -vf  /usr/share/fish/vendor_conf.d/ublue-brew.fish
        rm -vf  /usr/share/fish/vendor_conf.d/nano-default-editor.fish
        rm -vf  /usr/share/fish/functions/fish_greeting.fish
        rm -rvf /usr/share/ublue-os/bazaar/blocklist.txt
        rm -rvf /usr/share/ublue-os/dconfs
        rm -rvf /usr/share/ublue-os/flatpak-blocklist
        rm -rvf /usr/share/ublue-os/motd

        log "INFO" "Removing ublue/bazzite defaults in /etc/profile.d"
        rm -vf /etc/profile.d/askpass.sh
        rm -vf /etc/profile.d/bazzite-neofetch.sh
        rm -vf /etc/profile.d/brew.sh
        rm -vf /etc/profile.d/brew-bash-completion.sh
        rm -vf /etc/profile.d/user-motd.sh
    fi

    log "INFO" "Removing dconf and skel defaults"
    rm -rvf /etc/skel/*
    rm -rvf /etc/skel/.*
    rm -rvf /etc/dconf/db/distro.d/*
    rm -rvf /usr/etc/skel/*
    rm -rvf /usr/etc/skel/.*
    rm -rvf /usr/etc/dconf/db/distro.d/*

    log "INFO" "Removing profile.d scripts"
    rm -vf /etc/profile.d/toolbox.sh

    log "INFO" "Removing localsearch db miner"
    rm -vf /usr/lib/systemd/user/tracker*3.service
    rm -vf /usr/lib/systemd/user/localsearch*3.service

    log "INFO" "Removing desktop files in xdg autostart directory"
    rm -vf /etc/xdg/autostart/ibus-mozc-launch-xwayland.desktop
    rm -vf /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop
    rm -vf /etc/xdg/autostart/org.gnome.Software.desktop
    rm -vf /etc/xdg/autostart/nvidia-settings-load.desktop
    rm -vf /etc/xdg/autostart/localsearch*3.desktop
    rm -vf /etc/xdg/autostart/tracker*3.desktop
    rm -vf /etc/xdg/autostart/steam.desktop

    log "INFO" "Removing unneeded repos"
    rm -vf /etc/yum.repos.d/charm.repo
    rm -vf /etc/yum.repos.d/google-chrome.repo
    rm -vf /etc/yum.repos.d/tailscale.repo

    log "INFO" "Cleanup done"
fi
