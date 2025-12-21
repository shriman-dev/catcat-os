#!/usr/bin/env bash
set -oue pipefail
SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Copying over default system configurations and files"
FILESDIR="$(dirname ${SETUP_DIR})"
cp -drf  ${FILESDIR}/system/* /
cp -arvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
cp -arvf ${FILESDIR}/dconf/*  /usr/etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/skel     /etc/
log "INFO" "Copying done."
