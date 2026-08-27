#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euo pipefail

HWACCEL_PKGS=(
    # Image and Video
    "ffmpegthumbnailer"
    "libopenjph"

    # Hw and graphics
    "intel-opencl"
    "intel-vpl-gpu-rt"

    # Audio
    "alsa-firmware"
    "pipewire-module-filter-chain-sofa"

    # Performance Tuning
    #"corectrl"
    #"lact"                       # From terra
    #"irqbalance"
    #"cardwire-gui"               # From terra # A GPU Manager and switcher for linux
    "dmemcg-booster"             # From terra
    "vulkan-tools"
    "vulkan-low-latency-layer"   # From terra

    # Needed deps
    "mesa-demos"                 # dep of quickemu
)

NTIVO_PKGS=(
    "ffmpeg-libs"
    "rar"
    "libva-utils"
    "intel-vaapi-driver"
    "pipewire-libs-extra"
    "mesa-libOpenCL"
)

NTIVO_SYNC=(
    "intel-gmmlib"
    "intel-mediasdk"
    #"intel-vpl-gpu-rt"
    "libva-intel-media-driver"
    "libva"
    "libheif"
    "mesa-dri-drivers"
    "mesa-filesystem"
    "mesa-libEGL"
    "mesa-libGL"
    "mesa-libgbm"
    "mesa-vulkan-drivers"
    "mesa-va-drivers"
    "gstreamer1-plugin-libav"
)

declare -A NTIVO_SWAP=(
    ["ffmpeg-free"]="ffmpeg"
    ["fdk-aac-free"]="libfdk-aac"
    ["gstreamer1-plugins-ugly-free"]="gstreamer1-plugins-ugly"
    ["libavcodec-free"]="libavcodec"
    ["libavdevice-free"]="libavdevice"
    ["libavfilter-free"]="libavfilter"
    ["libavformat-free"]="libavformat"
    ["libavutil-free"]="libavutil"
    ["libswresample-free"]="libswresample"
    ["libswscale-free"]="libswscale"
)

pkgs_hwaccel() {
    local pkg
    log "INFO" "Installing Hardware Acceleration Packages"
    # From Terra Repo
#    dnf_action swap from-repo "terra" switcheroo-control cardwire
    dnf_action swap from-repo "terra-extras" uresourced uresourced-dmemcg
    dnf_action install repo "terra,terra-extras" "${HWACCEL_PKGS[@]}"

    # Exclude Mesa from all Fedora and Terra repos except Negativo17's fedora-multimedia
    #dnf5 -y config-manager setopt "*rpmfusion*".exclude="mesa-*"
    dnf5 -y config-manager setopt "*fedora*.exclude=mesa-*"
    dnf5 -y config-manager setopt "*terra*.exclude=mesa-*"
    dnf5 -y config-manager setopt "fedora-multimedia".exclude=

    # From Negativo17 Multimedia Repo
    dnf_action distro-sync from-repo "fedora-multimedia" weak-deps "${NTIVO_SYNC[@]}"
    for pkg in "${!NTIVO_SWAP[@]}"; do
        dnf_action swap from-repo "fedora-multimedia" weak-deps "${pkg}" "${NTIVO_SWAP["${pkg}"]}"
    done
    # More packages
    dnf_action install from-repo "fedora-multimedia" weak-deps "${NTIVO_PKGS[@]}"

    log "INFO" "Hardware Acceleration packages installed successfully"
}
pkgs_hwaccel

