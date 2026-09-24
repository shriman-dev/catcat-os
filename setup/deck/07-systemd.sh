#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

#log "INFO" "Enabling system services"

#log "INFO" "Enabled system services"

log "INFO" "Disabling and masking system services"
systemctl -v disable ds-inhibit.service || true
systemctl -v mask ds-inhibit.service || true
log "INFO" "Disabled system services"
