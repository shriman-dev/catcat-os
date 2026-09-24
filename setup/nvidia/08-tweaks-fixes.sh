#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Applying NVIDIA specific tweaks"
echo '# I2C support on NVIDIA
options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100
' > /etc/modprobe.d/nvidia_i2c.conf

# Blacklist nouveau and add Nvidia modesetting support
echo '# Modesetting must be disabled in case of SLI Mosaic
options nvidia-drm modeset=1 fbdev=1

blacklist nouveau
options nouveau modeset=0
' > /usr/lib/modprobe.d/nvidia-modeset.conf
cp -v /usr/lib/modprobe.d/nvidia-modeset.conf /etc/modprobe.d/nvidia-modeset.conf

log "INFO" "System tweaks applied"

log "INFO" "Applying system fixes"
# Must force driver load to fix black screen on boot for nvidia desktops
sed -i 's|omit_drivers|force_drivers|g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
# Also must pre-load intel/amd iGPU else chromium web browsers fail to use hardware acceleration
sed -i 's| nvidia | i915 amdgpu nvidia |g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
cat /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
log "INFO" "System fixes applied"
