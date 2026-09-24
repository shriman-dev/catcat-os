#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

COPR_LIST=("hhd-dev/hhd")
DECK_PACKAGES=(
#    "jupiter-fan-control"
#    "galileo-mura" # Utility designed to mitigate uneven brightness or graininess on OLED screens
#    "steamdeck-dsp"
#    "powerbuttond"
#    "inputplumber"
#    "steamos-manager-powerstation"
#    "vpower"
#    #"steam-notif-daemon"
#    "acpica-tools"
#    "sdgyrodsu"
#    "socat"
#    "python-vdf"
#    "python-crcmod"
    "gcc"
    "make"
    "hhd"
    "hhd-ui"
    "adjustor"
    "kernel-headers"
    "${CUSTOM_KERNEL:-kernel}-devel-matched"
    "++acpi_call"
)

rpm_repos enable
pkgs_install "deck" "${DECK_PACKAGES[@]}"
rpm_repos disable
