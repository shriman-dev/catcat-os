#!/usr/bin/env bash
set -oue pipefail
SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Debloating image"
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
sudo dnf5 -y remove \
                bazaar \
                btrfs-assistant \
                fastfetch \
                f"$(rpm -E %fedora)"-backgrounds-base \
                fedora-workstation-backgrounds \
                gnome-browser-connector \
                gnome-initial-setup \
                gnome-shell-extension-appindicator \
                gnome-shell-extension-blur-my-shell \
                gnome-shell-extension-caffeine \
                gnome-shell-extension-compiz-alike-magic-lamp-effect \
                gnome-shell-extension-compiz-windows-effect \
                gnome-shell-extension-just-perfection \
                libvirt \
                libvirt-libs \
                nvtop \
                openssh-askpass \
                plocate \
                steamdeck-backgrounds \
                stress-ng \
                sunshine \
                tailscale \
                topgrade \
                uupd \
                webapp-manager \
                yelp
log "INFO" "Done."

