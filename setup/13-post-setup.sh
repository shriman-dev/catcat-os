#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

# Kernel sign checks
log "INFO" "Verifying kernel checksum generated during secureboot signing"
ker_sigsha_dir="/usr/share/${PROJECT_NAME}/kernel_sigsha"
for kver_sha in "${ker_sigsha_dir}"/*.sha; do
    sha256sum -c "${kver_sha}" ||
        die "Kernel was modified, checksum mismatch for kernel version: ${kver_sha}"
done
log "INFO" "Kernel checksum verified"

log "INFO" "Running post setup cleanup"
# Remove packages no longer needed
log "INFO" "Running package removal"
"${BUILD_SETUP_DIR}"/setup_lib/pkgs-kernel.sh remove-devel
"${BUILD_SETUP_DIR}"/03-debloat.sh remove-devel
log "INFO" "Packages removed"


# Remove junk
# Disable gnome software running in background
if rpm -q gnome-software; then
    log "INFO" "Disabling gnome software from running in background"
    rm -vf /etc/xdg/autostart/org.gnome.Software.desktop \
           /usr/etc/xdg/autostart/org.gnome.Software.desktop \
           /usr/lib/systemd/user/gnome-software.service \
           /usr/share/dbus-1/services/org.gnome.Software.service \
           /usr/share/dbus-1/services/org.freedesktop.PackageKit.service
fi

# Remove more stuffs in skel
#/etc/skel/.config/autostart
#/etc/skel/.config/user-tmpfiles.d \
rm -rvf /etc/skel/.mozilla \
        /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vapor.palette \
        /etc/skel/.local/share/org.gnome.Ptyxis/palettes/vgui2.palette

# Remove symlink resolv conf and create empty one
if [[ -L "/etc/resolv.conf" ]]; then
    rm -v "/etc/resolv.conf"
    touch "/etc/resolv.conf"
fi

# Copy entries into /usr/lib/passwd and /usr/lib/group
if out=$(grep -v root /etc/passwd); then
    log "INFO" "Moving passwd users to /usr/lib/passwd"
    echo "${out}" >> /usr/lib/passwd
    echo "root:x:0:0:root:/root:/bin/bash" > /etc/passwd
fi

if out=$(grep -v "root\|wheel" /etc/group); then
    log "INFO" "Moving group entries to /usr/lib/group"
    echo "${out}" >> /usr/lib/group
    echo "root:x:0:" > /etc/group
    echo "wheel:x:10:" >> /etc/group
fi
unset out

# Extra lock files created by container processes that might cause issues
rm -vf /etc/.pwd.lock \
       /etc/passwd- \
       /etc/group- \
       /etc/shadow- \
       /etc/gshadow- \
       /etc/subuid- \
       /etc/subgid-

#dnf5 clean all
find /var/* \
    -maxdepth 0 -type d \
    -not -name "cache" \
    -exec rm -rvf {} \;
find /var/cache/* -maxdepth 0 -type d \
    -not -name "libdnf*" \
    -not -name "rpm-ostree" \
    -not -name "${PROJECT_NAME}" \
    -exec rm -fr {} \;


log "INFO" "Post setup configuration"
mkdir -vp /var/tmp
chmod -vR 1777 /var/tmp

#gdu /usr --non-interactive
