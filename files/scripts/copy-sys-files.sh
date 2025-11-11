#!/usr/bin/env bash
set -oue pipefail
SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Copying over default system configurations and files"
FILESDIR="$(dirname ${SETUP_DIR})"
cp -drf  ${FILESDIR}/system/* /
cp -drvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
cp -drvf ${FILESDIR}/dconf/*  /usr/etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/skel     /etc/
log "INFO" "Copying done."

# Import justfiles to ujust
log "INFO" "Importing justfiles to ujust"
IMPORT_FILE="/usr/share/ublue-os/justfile"
JUSTFILE_DIR="${FILESDIR}/justfiles"
if [[ -f "${IMPORT_FILE}" ]]; then
    for JUSTFILE in ${JUSTFILE_DIR}/*.just; do
        # Copy justfiles to ujust default directory
        cp -dvf "${JUSTFILE}" /usr/share/ublue-os/just/
        # Add import line if it does not exists already
        IMPORT_LINE="import \"/usr/share/ublue-os/just/$(basename ${JUSTFILE})\""
        grep -w "${IMPORT_LINE}" "${IMPORT_FILE}" || {
            sed -i "/# Imports/a\\${IMPORT_LINE}" "${IMPORT_FILE}"
            log "DEBUG" "Added: '${IMPORT_LINE}' to ${IMPORT_FILE}"
        }
    done
fi
log "INFO" "All Justfile imports are done."

log "INFO" "Full output of: ${IMPORT_FILE}"
cat "${IMPORT_FILE}"
