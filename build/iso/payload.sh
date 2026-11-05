#!/usr/bin/bash
set -euo pipefail
source /usr/lib/catcat-os/bash-lib.sh
set -x

# Prepare Environment
# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# Allow bwrap to write to /proc/sys/user/max_user_namespaces
# By default /proc/sys is mounted as ro, so remount it as rw
mount -o remount,rw /proc/sys

# Pull the container image to be installed
podman pull "${PROJECT_REGISTRY}/${IMAGE_NAME}:${DEFAULT_TAG}"

# Allow squashfs
sed -i -e "s|^install squashfs|#install squashfs|" /usr/lib/modprobe.d/secureblue.conf
echo 'install squashfs /sbin/modprobe --ignore-install squashfs' > \
        /etc/modprobe.d/zz-squashfs-override.conf


# Regenerate InitRamFS
dnf install -y dracut-live
readarray -t KERNEL_PATH < \
    <(find /usr/lib/modules -mindepth 2 -maxdepth 2 -type f -name "vmlinuz" -exec dirname -- {} \;)

kernel_ver="$(basename -- "${KERNEL_PATH[0]}")"
initramfs_image="${KERNEL_PATH[0]}/initramfs.img"

DRACUT_NO_XATTR=1 \
dracut  --verbose --reproducible --no-hostonly \
        --zstd --force \
        --add "dmsquash-live dmsquash-live-autooverlay" \
        --kver "${kernel_ver}" \
        "${initramfs_image}"


# Install Packages
ISO_PACKAGES=(
    "anaconda"
    "anaconda-install-img-deps"
    "anaconda-dracut"
    "dracut-config-generic"
    "dracut-network"
    "libblockdev-btrfs"
    "libblockdev-lvm"
    "libblockdev-dm"
    "kernel-headers"
    "net-tools"
    "grub2-efi-x64-cdboot"
    "squashfs-tools"
    "xorrisofs"
    "isomd5sum"
    "livesys-scripts"
)

dnf5 install -y "${ISO_PACKAGES[@]}"


# Install Flatpak Packages
# Add flathub repo
curl_get /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify --system --prio=10 flathub

# Install flatpaks
source /etc/catcat-os/flatpak/pkgs-flatpak.sh
flatpak install --or-update --system -y --noninteractive \
        flathub "${DESKTOP_COMMON[@]}" "${DESKTOP_EXTRAS[@]}"

# Configure Systemd Services
systemctl disable bootloader-update.service


# Tweaks and Configurations
# Configure livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=gnome/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# Anaconda configuration
tee /etc/anaconda/conf.d/anaconda.conf <<'EOF'
[Payload]
flatpak_remote = flathub https://dl.flathub.org/repo/
EOF

tee /etc/anaconda/profile.d/catcat-os.conf <<'EOF'
# Anaconda configuration file for CatCat OS

[Profile]
# Define the profile
profile_id = catcat-os

[Profile Detection]
# Match os-release values
os_id = catcat-os

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/silverblue/fedora-silverblue.css
hidden_spokes =
    NetworkSpoke

hidden_webui_pages =
    root-password
    network

[Localization]
use_geolocation = False
EOF

tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ${PROJECT_REGISTRY}/${IMAGE_NAME}:${DEFAULT_TAG}
%end
EOF

tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=${PROJECT_REGISTRY}/${IMAGE_NAME}:${DEFAULT_TAG} --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
EOF


sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true
sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/fedora-logo-icon.png|' /usr/share/applications/liveinst.desktop || true
sed -i 's| Fedora| CatCat OS|' /usr/share/anaconda/gnome/fedora-welcome || true
sed -i 's|Activities|in the dock|' /usr/share/anaconda/gnome/fedora-welcome || true


# Set the timezone to UTC
rm -f /etc/localtime
systemd-firstboot --timezone UTC

# image-builder expects the EFI directory to be in /boot/efi
mkdir -p /boot/efi
ocopy -v /usr/lib/efi/*/*/EFI /boot/efi

# Copy in the ISO config for image-builder
mkdir -p /usr/lib/bootc-image-builder
cp /src/files/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

# / in a booted live ISO is an overlayfs with upperdir pointed somewhere under /run
# This means that /var/tmp is also technically under /run.
# /run is of course a tmpfs, but set with quite a small size.
# ostree needs quite a lot of space on /var/tmp for temporary files so /run is not enough.
# Mount a larger tmpfs to /var/tmp at boot time to avoid this issue.
rm -rf /var/tmp
mkdir /var/tmp
tee /etc/systemd/system/var-tmp.mount << 'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount



