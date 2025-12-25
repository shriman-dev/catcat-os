#!/usr/bin/env bash
set -oue pipefail
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Copying over default system configurations and files"
cp -vf ${SETUP_DIR}/setup_files/cosign.pub /etc/pki/containers/catcat-os.pub

FILESDIR="$(dirname ${SETUP_DIR})"
cp -drf  ${FILESDIR}/system/* /
cp -arvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/skel     /etc/
log "INFO" "Copying done."
