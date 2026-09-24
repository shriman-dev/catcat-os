#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail
log "INFO" "Fetching remote configurations"
SYS_CACHE="${BUILD_CACHE_DIR}/system-${IMAGE_NAME}"
bazz_repo="ublue-os/bazzite"
remote_d="system_files/deck/shared"

declare -A remote_map=(
    ["etc/bluetooth"]="${remote_d}/etc/bluetooth:main.conf"
    ["etc/modules-load.d"]="${remote_d}/etc/modules-load.d:hid-steaminput-preload.conf"
    ["etc/systemd/logind.conf.d"]="${remote_d}/etc/systemd/logind.conf.d:deck.conf"
    ["usr/share/color/icc/colord"]="${remote_d}/usr/share/color/icc/colord:Legion_GO_BT1886.icc"
    ["usr/share/pipewire/hardware-profiles/lenovo-83e1"]="${remote_d}/usr/share/pipewire/hardware-profiles/lenovo-83e1:multiwayCor48.wav"
    ["usr/share/pipewire/hardware-profiles/lenovo-83e1/pipewire.conf.d"]="${remote_d}/usr/share/pipewire/hardware-profiles/lenovo-83e1/pipewire.conf.d:filter-chain.conf"
)

for local_path in "${!remote_map[@]}"; do
    IFS=':' read -r repo_path filename <<< "${remote_map[${local_path}]}"
    get_ghraw --dstd "${SYS_CACHE}/${local_path}" --repo "${bazz_repo}" \
              --repod "${repo_path}" -f "${filename}"
done

get_ghraw \
    --dstd "${SYS_CACHE}/usr/share/wireplumber/hardware-profiles/lenovo-83e1/wireplumber.conf.d" \
    --repo "${bazz_repo}" \
    --repod "${remote_d}/usr/share/wireplumber/hardware-profiles/lenovo-83e1/wireplumber.conf.d" \
    --flist "51-preferHDMI.conf" "60-raise-internal-mic.conf" "alsa-card0.conf" "alsa-card1.conf"

get_ghraw \
    --dstd "${SYS_CACHE}/usr/share/wireplumber/wireplumber.conf.d" \
    --repo "${bazz_repo}" \
    --repod "${remote_d}/usr/share/wireplumber/wireplumber.conf.d" \
    --flist "alsa-card0.conf" "alsa-card1.conf" "alsa-ps-controller.conf" "bluez.conf"

log "INFO" "Copying cached files"
ocopy "${SYS_CACHE}" /
log "INFO" "Fetching done"
