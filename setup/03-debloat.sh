#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

#avahi avahi-libs fuse-sshfs irqbalance
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
REMOVE_PKGS=(
    "azure-vm-utils"
    "bazaar"
    "btrfs-assistant"
    "coreos-installer"
    "docker-cli"
    "fastfetch"
    #"f$(rpm -E %fedora)-backgrounds-base"
    "fedora-bookmarks"
    "fedora-chromium-config*"
    "fedora-flathub-remote"
    "fedora-third-party"
    "fedora-workstation-backgrounds"
    "firefox*"
    "flatpak-spawn"
    "gnome-browser-connector"
    "gnome-extensions-app"
    "gnome-initial-setup"
    "gnome-remote-desktop"
    "gnome-shell-extension-*"
    "gnome-software-rpm-ostree"
    "gnome-terminal-nautilus"
    "gnome-tour"
    "google-compute-engine-guest-configs-udev"
    "htop"
    "httpd*"
    "httpd-core"
    "libvirt"
    "libvirt-libs"
    "libvncserver"
    "moby-engine"
    "mod_dnssd"
    "mod_http2"
    "mod_lua"
    "NetworkManager-cloud-setup"
    "nvtop"
    "openssh-askpass"
    "passim"
    "plocate"
    "rar"
    "snapper"
    "steamdeck-backgrounds"
    "Sunshine"
    "sunshine"
    "tailscale"
    "toolbox"
    "totem-video-thumbnailer"
    "topgrade"
    "ublue-brew"
    "ublue-os-update-services"
    "unrar"
    "uupd"
    "WALinuxAgent-udev"
    "webapp-manager"
    "xdotool"
    "ydotool"
    "yelp*"
    "zincati"
    "zram-generator-defaults"
)

DEVEL_PKGS=(
    "make"
    "gcc"
    "gcc-c++"
    "akmod-nvidia"
    "akmods"
)

KERNEL_PKGS=(
    "kernel"
    "kernel-core"
    "kernel-devel"
    "kernel-devel-matched"
    "kernel-modules"
    "kernel-modules-core"
#    "kernel-modules-extra"
)

if [[ $# -eq 0 ]]; then
    log "INFO" "Debloating..."
    dnf5 -y remove "${REMOVE_PKGS[@]}"
    dnf5 -y autoremove
    if [[ -n "${CUSTOM_KERNEL:-}" ]]; then
        dnf5 -y versionlock delete "${KERNEL_PKGS[@]}" || true
        dnf5 -y --setopt=protect_running_kernel=False \
                remove --no-autoremove "${KERNEL_PKGS[@]}"
        (cd /usr/lib/modules && rm -rvf -- ./*)
    fi
    log "INFO" "Debloat Done"
fi

if [[ $# -gt 0 ]]; then
    case "${1}" in
        remove-devel)
            log "INFO" "Removing devel packages..."
            dnf5 -y remove "${DEVEL_PKGS[@]}"
            dnf5 -y autoremove
            ;;
        *) die "Unknown argument: ${1}";;
    esac
fi
