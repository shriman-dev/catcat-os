#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Copying over default system configurations and files"

BUILD_FILES_DIR="${BUILD_ROOT}/files"
cp -drf  "${BUILD_FILES_DIR}/system"/* /
cp -arvf "${BUILD_FILES_DIR}/dconf"/*  /etc/dconf/db/distro.d/
log "INFO" "Copying done"
