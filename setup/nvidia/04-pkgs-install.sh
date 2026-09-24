#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

pkgs_nvidia() {
    local kernel_ver kmod_ver driver_ver
    kernel_ver="$(rpm -q "${CUSTOM_KERNEL:-kernel}" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n')"

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

    # Verify drivers
    kmod_ver="$(rpm -q akmod-nvidia --queryformat '%{VERSION}\n')"
    driver_ver="$(rpm -q nvidia-driver --queryformat '%{VERSION}\n')"

    [[ "${kmod_ver}" != "${driver_ver}" ]] && die "NVIDIA Drivers version mismatch"

    modinfo \
      "/usr/lib/modules/${kernel_ver}/extra/nvidia"/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz \
      >/dev/null ||
          die "NVIDIA Drivers installation failed" "cat /var/cache/akmods/nvidia/*.failed.log"

    # Finalize
    # SELinux policies for NVIDIA image
    curl_get "${BUILD_CACHE_DIR}/fetched/nvidia-container.pp" \
         "https://raw.githubusercontent.com/NVIDIA/dgx-selinux/master/bin/RHEL9/nvidia-container.pp"
    semodule -i "${BUILD_CACHE_DIR}/fetched/nvidia-container.pp"

    depmod -a "${kernel_ver}"
    log "INFO" "NVIDIA Drivers installation successful"
}

rpm_repos enable
pkgs_nvidia
rpm_repos disable
