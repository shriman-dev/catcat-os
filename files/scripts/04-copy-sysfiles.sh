#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

BUILD_FILES_DIR="${BUILD_ROOT_DIR}/files"
SYS_CACHE="${BUILD_CACHE_DIR}/system-remote-configs"
FETCHED="${BUILD_CACHE_DIR}/fetched"

log "INFO" "Copying default configurations and files"
# CachyOS settings
ocopy "${BUILD_CACHE_DIR}/conf_repos/cachyos_settings" / \
      'usr/bin/dlss-swapper*' \
      'usr/lib/modprobe.d/nvidia.conf' \
      'usr/lib/udev/rules.d/71-nvidia.rules'
mv -v /usr/lib/modprobe.d/amdgpu.conf /usr/lib/modprobe.d/cachy-amdgpu.conf
mv -v /usr/lib/modprobe.d/blacklist.conf /usr/lib/modprobe.d/cachy-blacklist.conf

# Default settings
ocopy    "${BUILD_FILES_DIR}/system" /
ocopy -v "${BUILD_FILES_DIR}/dconf" /etc/dconf/db/distro.d

log "INFO" "Fetching remote configurations"
# Justfiles
get_ghraw --dstd "${FETCHED}/justfiles" --repo "ublue-os/bazzite" \
          --repod "system_files/desktop/shared/usr/share/ublue-os/just" \
          -f "82-bazzite-waydroid.just"

# Udev rules
get_ghraw --dstd "${SYS_CACHE}/usr/lib/udev/rules.d" --repo "M0Rf30/android-udev-rules" \
          -f "51-android.rules"
get_ghraw --dstd "${SYS_CACHE}/usr/lib/udev/rules.d" --repo "ublue-os/bazzite" \
          --repod "system_files/desktop/silverblue/usr/lib/udev/rules.d" \
          -f "80-gpu-reset.rules"

if [[ ! -d "${FETCHED}/gamedev_udev" ]]; then
    curl_get "/tmp/game-devices-udev.zip" \
        "https://codeberg.org/fabiscafe/game-devices-udev/archive/main.zip" &&
    unarchive "/tmp/game-devices-udev.zip" "${FETCHED}/gamedev_udev"
fi

ocopy -v "${BUILD_CACHE_DIR}/conf_repos/ublue_packages/packages/ublue-os-udev-rules/src/udev-rules.d" \
         "/usr/lib/udev/rules.d"
ocopy -v "${FETCHED}/gamedev_udev/game-devices-udev/src" \
         "/usr/lib/udev/rules.d"

# Modules blacklist from secureblue
get_ghraw --dstd "${SYS_CACHE}/usr/lib/modprobe.d" --repo "secureblue/secureblue" \
          --repod "files/system/usr/lib/modprobe.d" \
          --flist "secureblue.conf" "secureblue-framebuffer.conf"
sed -i -e 's/^install bluetooth/# &/' \
       -e 's/^install btusb/# &/' "${SYS_CACHE}/usr/lib/modprobe.d/secureblue.conf"

# Chrony Configuration
get_ghraw --dstd "${SYS_CACHE}/etc" --repo "secureblue/secureblue" \
          --repod "files/system/etc" -f "chrony.conf"

# Copy cached files
ocopy "${SYS_CACHE}" /
log "INFO" "Copying done"
