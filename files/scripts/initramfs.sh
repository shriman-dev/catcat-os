#!/usr/bin/env bash
set -euo pipefail
echo -e "\n$0\n"

if ! command -v rpm-ostree &> /dev/null || ! command -v bootc &> /dev/null; then
  echo "This module is only compatible with Fedora Atomic images"
  exit 1
fi

# If images already installed cliwrap, use it. Only used in transition period, so it should be removed when base images like Ublue remove cliwrap
if [[ -f "/usr/libexec/rpm-ostree/wrapped/dracut" ]]; then
  DRACUT="/usr/libexec/rpm-ostree/wrapped/dracut"
else
  DRACUT="/usr/bin/dracut"
fi

# NOTE!
# This won't work when Fedora starts to utilize UKIs (Unified Kernel Images).
# UKIs will contain kernel + initramfs + bootloader.
# Refactor the module to support UKIs once they are starting to be used, if possible.
# That won't be soon, so this module should work for good period of time

KERNEL_MODULES_PATH="/usr/lib/modules"
readarray -t QUALIFIED_KERNEL < <(find "${KERNEL_MODULES_PATH}" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

if [[ "${#QUALIFIED_KERNEL[@]}" -gt 1 ]]; then
  if [[ "${QUALIFIED_KERNEL[@]}" =~ 'bazzite' ]]; then
    echo "WARNING: multiple kernels found with bazzite kernel. Defaulting to the bazzite kernel"
    QUALIFIED_KERNEL=$(printf "%s\n" "${QUALIFIED_KERNEL[@]}" | grep bazzite)
  else
    echo "ERROR: Bazzite kernel not found to set as default."
    echo "ERROR: There are several versions of kernel's initramfs."
    echo "       Please only include 1 kernel in the image to solve this issue."
    exit 1
  fi
fi

INITRAMFS_IMAGE="${KERNEL_MODULES_PATH}/${QUALIFIED_KERNEL}/initramfs.img"

echo "Starting initramfs regeneration for kernel version: ${QUALIFIED_KERNEL}"

"${DRACUT}" --no-hostonly --kver "${QUALIFIED_KERNEL}" --reproducible -v --add ostree -f "${INITRAMFS_IMAGE}"
chmod 0600 "${INITRAMFS_IMAGE}"
