#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Copying and fetching configurations"
SYS_CACHE="${BUILD_CACHE_DIR}/system-${IMAGE_NAME}"
cp -vf "${BUILD_CACHE_DIR}/conf_repos/cachyos_settings/usr/bin"/dlss-swapper* \
       "/usr/bin"/
cp -vf "${BUILD_CACHE_DIR}/conf_repos/cachyos_settings/usr/lib/modprobe.d/nvidia.conf" \
       "/usr/lib/modprobe.d/cachy-nvidia.conf"
cp -vf "${BUILD_CACHE_DIR}/conf_repos/cachyos_settings/usr/lib/udev/rules.d/71-nvidia.rules" \
       "/usr/lib/udev/rules.d"/

get_ghraw --dstd "${SYS_CACHE}/usr/lib/systemd/system" --repo "blue-build/base-images" \
          --repod "files/nvidia/usr/lib/systemd/system" -f "nvctk-cdi.service"

log "INFO" "Copying cached files"
ocopy "${SYS_CACHE}" /
log "INFO" "Copying done"
