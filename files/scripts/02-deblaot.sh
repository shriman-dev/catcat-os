#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Debloating image"
#avahi avahi-libs fuse-sshfs irqbalance
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
[[ ! -d "/etc/${PROJECT_NAME}" ]] &&
    dnf5 -y remove \
        azure-vm-utils \
        bazaar \
        btrfs-assistant \
        coreos-installer \
        docker-cli \
        fastfetch \
        f"$(rpm -E %fedora)"-backgrounds-base \
        fedora-bookmarks \
        fedora-chromium-config* \
        fedora-flathub-remote \
        fedora-third-party \
        fedora-workstation-backgrounds \
        firefox* \
        gnome-browser-connector \
        gnome-extensions-app \
        gnome-initial-setup \
        gnome-remote-desktop \
        gnome-shell-extension-* \
        gnome-software-rpm-ostree \
        gnome-terminal-nautilus \
        gnome-tour \
        google-compute-engine-guest-configs-udev \
        htop \
        httpd \
        httpd-core \
        libvirt \
        libvirt-libs \
        libvncserver \
        moby-engine \
        mod_dnssd \
        mod_http2 \
        mod_lua \
        NetworkManager-cloud-setup \
        nvtop \
        openssh-askpass \
        passim \
        plocate \
        rar \
        snapper \
        steamdeck-backgrounds \
        Sunshine \
        sunshine \
        tailscale \
        toolbox \
        totem-video-thumbnailer \
        topgrade \
        ublue-brew \
        ublue-os-update-services \
        unrar \
        uupd \
        WALinuxAgent-udev \
        webapp-manager \
        xdotool \
        ydotool \
        yelp \
        zincati

    dnf5 -y autoremove

log "INFO" "Debloat Done"
