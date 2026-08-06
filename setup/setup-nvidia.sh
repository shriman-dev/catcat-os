#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

##############
# Debloating #
##############
log "INFO" "Debloating..."
dnf5 -y remove \
        amdgpu_top \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi \
        amdsmi
dnf5 -y autoremove
log "INFO" "Debloat Done"


#######################
# Installing Packages #
#######################
pkgs_nvidia() {
    local kernel_ver="$(rpm -q ${CUSTOM_KERNEL:-kernel} --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n')"

    log "INFO" "Installing NVIDIA Drivers Packages"
    dnf_action install kernel-headers "${CUSTOM_KERNEL:-kernel}"-devel-matched \
                       akmods gcc gcc-c++

    # TODO: remove this when fixed upstream
    sed -i.bak '/if \[\[ -w \/var \]\] ; then/,/fi/d' /usr/sbin/akmodsbuild
    chmod -v +x /usr/sbin/akmodsbuild

    dnf_action install from-repo "fedora-nvidia" \
                       akmod-nvidia nvidia-kmod-common nvidia-modprobe

    akmods --kernels "${kernel_ver}" --kmod "nvidia" --force
    cat /var/cache/akmods/nvidia/*.failed.log || true

    mv /usr/sbin/akmodsbuild.bak /usr/sbin/akmodsbuild

    # Verify drivers
    local kmod_ver="$(rpm -q akmod-nvidia --queryformat '%{VERSION}\n')"
    local negativo_ver="$(rpm -q nvidia-modprobe --queryformat '%{VERSION}\n')"

    [[ "${kmod_ver}" != "${negativo_ver}" ]] && die "NVIDIA Drivers version mismatch"

    modinfo \
      "/usr/lib/modules/${kernel_ver}/extra/nvidia"/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz \
      >/dev/null ||
          die "NVIDIA Drivers installation failed" "cat /var/cache/akmods/nvidia/*.failed.log"

    # Install NVIDIA packages
    [[ ! -f /etc/pki/tls/certs/ca-bundle.crt ]] &&
        ln -svf /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
                /etc/pki/tls/certs/ca-bundle.crt

    dnf_action install nvtop libva-nvidia-driver
    dnf_action install from-repo "fedora-nvidia" \
                       libnvidia-cfg libnvidia-fbc libnvidia-gpucomp libnvidia-ml \
                       nvidia-driver nvidia-driver-common nvidia-driver-cuda \
                       nvidia-persistenced nvidia-settings
    dnf_action install from-repo "nvidia-container-toolkit" \
                       nvidia-container-toolkit

    # Finalize
    # SELinux policies for NVIDIA image
    curl_get "${BUILD_CACHE_DIR}/nvidia-container.pp" \
         "https://raw.githubusercontent.com/NVIDIA/dgx-selinux/master/bin/RHEL9/nvidia-container.pp"
    semodule -i "${BUILD_CACHE_DIR}/nvidia-container.pp"

    depmod -a "${kernel_ver}"
    log "INFO" "NVIDIA Drivers installation successful"
}

rpm_repos enable
pkgs_nvidia
rpm_repos disable


#####################################
# Copying Over System Default Files #
#####################################
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


################################
# Configuring Systemd Services #
################################
log "INFO" "Enabling system services"
systemctl -f enable nvctk-cdi.service

DISABLE_SERVICES=(
    "akmods-keygen@akmods-keygen.service"
    "akmods-keygen.target"
)

log "INFO" "Disabling and masking system services"
systemctl -v disable ${DISABLE_SERVICES[@]} || true
systemctl -v mask ${DISABLE_SERVICES[@]} || true


#########################################
# Refining System With Tweaks And Fixes #
#########################################
log "INFO" "Applying NVIDIA specific tweaks"
# Blacklist nouveau and add Nvidia modesetting support
echo '
# Modesetting must be disabled in case of SLI Mosaic

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


#######################
# Post Build Clean Up #
#######################
#log "INFO" "Running post package removal"
#dnf5 -y autoremove

