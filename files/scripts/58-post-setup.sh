#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Running post setup cleanup"

# Remove things that doesn't work well with NVIDIA
if [[ ${IMAGE_NAME} =~ "-nv" ]]; then
    log "INFO" "Removing packages unneeded on NVIDIA image"
    #nvidia-gpu-firmware
    dnf5 -y remove \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi
    log "INFO" "Done."
fi

# Disable gnome software running in background
if rpm -q gnome-software; then
    log "INFO" "Disabling gnome software from running in background"
    rm -vf /etc/xdg/autostart/org.gnome.Software.desktop
    rm -vf /usr/etc/xdg/autostart/org.gnome.Software.desktop
    rm -vf /usr/lib/systemd/user/gnome-software.service
    rm -vf /usr/share/dbus-1/services/org.gnome.Software.service
    rm -vf /usr/share/dbus-1/services/org.freedesktop.PackageKit.service
fi

# Remove cache and junk
dnf5 clean all
find /var/* -maxdepth 0 -type d -not -name "log" -not -name "cache" -exec rm -rvf {} \;
find /var/cache/* -maxdepth 0 -type d -not -name "libdnf5" -not -name "rpm-ostree" -exec rm -rvf {} \;
rm -rvf /var/log/*
rm -rvf /boot/.*
rm -rvf /boot/*
rm -rvf /tmp/*

# Remove symlinked resolv conf and create empty one
[[ -L /etc/resolv.conf ]] && rm -v /etc/resolv.conf
touch /etc/resolv.conf

# Remove more stuffs in skel
#/etc/skel/.config/autostart
rm -rvf /etc/skel/.mozilla
rm -rvf /etc/skel/.config/user-tmpfiles.d
rm -rvf /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vapor.palette
rm -rvf /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vgui2.palette


log "INFO" "Post setup configuration"
touch /etc/resolv.conf
mkdir -vp /var/tmp
chmod -vR 1777 /var/tmp
