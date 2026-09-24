#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Enabling system services"
systemctl -f enable nvctk-cdi.service
#systemctl -f enable nvidia-powerd.service

DISABLE_SERVICES=(
    "akmods-keygen@akmods-keygen.service"
    "akmods-keygen.target"
)

log "INFO" "Disabling and masking system services"
systemctl -v disable "${DISABLE_SERVICES[@]}" || true
systemctl -v mask "${DISABLE_SERVICES[@]}" || true
