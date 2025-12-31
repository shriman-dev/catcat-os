#!/usr/bin/env bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

log "INFO" "Copying over default system configurations and files"

FILESDIR="$(dirname ${BUILD_SETUP_DIR})"
cp -drf  ${FILESDIR}/system/* /
cp -arvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
log "INFO" "Copying done."
