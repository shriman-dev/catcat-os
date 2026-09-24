#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

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
