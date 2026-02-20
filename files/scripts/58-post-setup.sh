#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

# Kernel sign checks
if [[ -d "/tmp/kernel_sigsha" ]]; then
    log "INFO" "Verifying kernel checksum after signing"
    for kver_sha in /tmp/kernel_sigsha/*.sha; do
        sha256sum -c "${kver_sha}" ||
            die "Kernel was modified, shasum mismatch for kernel version: ${kver_sha}"
    done
    rm -rf "/tmp/kernel_sigsha"
    log "INFO" "Kernel checksum verified"
fi

log "INFO" "Running post setup cleanup"
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

# Remove resolv conf and create empty one
rm -v /etc/resolv.conf
touch /etc/resolv.conf

# Remove more stuffs in skel
#/etc/skel/.config/autostart
rm -rvf /etc/skel/.mozilla
rm -rvf /etc/skel/.config/user-tmpfiles.d
rm -rvf /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vapor.palette
rm -rvf /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vgui2.palette

# Remove packages no longer needed
log "INFO" "Running post package removal"
if [[ ${IMAGE_NAME} =~ (-mi|-sv) ]]; then
    dnf5 -y remove \
        make gcc gcc-c++ \
        kernel-headers \
        kernel-devel-matched
fi

if [[ ${IMAGE_NAME} =~ "-nv" ]]; then
    log "INFO" "Removing packages unneeded on NVIDIA image"
    #nvidia-gpu-firmware
    dnf5 -y remove \
        amdgpu_top \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi
fi


log "INFO" "Post setup configuration"
mkdir -vp /var/tmp
chmod -vR 1777 /var/tmp

gdu /usr --non-interactive
gdu /usr/etc --non-interactive
gdu /usr/src --non-interactive
gdu /usr/libexec --non-interactive
gdu /usr/bin --non-interactive
gdu /usr/lib --non-interactive
gdu /usr/lib64 --non-interactive
gdu /usr/share --non-interactive
