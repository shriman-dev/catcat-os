#!/usr/bin/env bash
source ${SETUP_DIR}/funcvar.sh
set -ouex pipefail

log "INFO" "Copying over default system configurations and files"

FILESDIR="$(dirname ${SETUP_DIR})"
cp -drf  ${FILESDIR}/system/* /
cp -arvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
log "INFO" "Copying done."
