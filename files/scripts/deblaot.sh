#!/usr/bin/env bash
set -oue pipefail
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Debloating image"

if [[ ${IMAGE_NAME} =~ "-sv" ]]; then
    dnf5 -y remove \
        NetworkManager-cloud-setup \
        WALinuxAgent-udev \
        avahi \
        avahi-libs \
        azure-vm-utils \
        coreos-installer \
        docker-cli \
        fuse-sshfs \
        google-compute-engine-guest-configs-udev \
        irqbalance \
        moby-engine \
        toolbox \
        zincati
fi

if [[ ! ${IMAGE_NAME} =~ "-sv" ]]; then
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
    dnf5 -y remove \
        bazaar \
        btrfs-assistant \
        fastfetch \
        f"$(rpm -E %fedora)"-backgrounds-base \
        fedora-bookmarks \
        fedora-chromium-config \
        fedora-chromium-config-gnome \
        fedora-flathub-remote \
        fedora-third-party \
        fedora-workstation-backgrounds \
        firefox \
        firefox-langpacks \
        gnome-browser-connector \
        gnome-extensions-app \
        gnome-initial-setup \
        gnome-remote-desktop \
        gnome-shell-extension-apps-menu \
        gnome-shell-extension-appindicator \
        gnome-shell-extension-background-logo \
        gnome-shell-extension-bazzite-menu \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-burn-my-windows \
        gnome-shell-extension-caffeine \
        gnome-shell-extension-caribou-blocker \
        gnome-shell-extension-compiz-alike-magic-lamp-effect \
        gnome-shell-extension-compiz-windows-effect \
        gnome-shell-extension-coverflow-alt-tab \
        gnome-shell-extension-desktop-cube \
        gnome-shell-extension-hotedge \
        gnome-shell-extension-just-perfection \
        gnome-shell-extension-launch-new-instance \
        gnome-shell-extension-places-menu \
        gnome-shell-extension-restart-to \
        gnome-shell-extension-search-light \
        gnome-shell-extension-supergfxctl-gex \
        gnome-shell-extension-tailscale-gnome-qs \
        gnome-shell-extension-window-list \
        gnome-software-rpm-ostree \
        gnome-terminal-nautilus \
        gnome-tour \
        htop \
        httpd \
        httpd-core \
        libvirt \
        libvirt-libs \
        libvncserver \
        mod_dnssd \
        mod_http2 \
        mod_lua \
        nvtop \
        openssh-askpass \
        passim \
        plocate \
        rar \
        snapper \
        steamdeck-backgrounds \
        stress-ng \
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
        webapp-manager \
        xdotool \
        ydotool \
        yelp
fi

log "INFO" "Done."
