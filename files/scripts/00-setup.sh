#!/usr/bin/env bash
export SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

enclosed_heading_this() {
    local text="${1}" padding_char="${2:-=}" output_width=${3:-120}
    enclosed_heading "${text}" "${padding_char}" ${output_width}
}

exec_script() {
    {
        local script="${1}"
        sed -E '/log ("DEBUG"|"INFO")/ s/$/; } 2>\/dev\/null/' "${script}" | \
        sed -Ee 's|log "INFO"|{ log "INFO"|g' \
            -e 's|log "DEBUG"|{ log "DEBUG"|g'
    } 2>/dev/null | bash
}

enclosed_heading_this "Building CatCat OS Image: ${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP} | With Commit: ${COMMIT_SHA}" "#"

set -ouex pipefail

{ enclosed_heading_this "Cleaning Up"; } 2>/dev/null
exec_script ${SETUP_DIR}/01-cleanup.sh
ostree container commit

{ enclosed_heading_this "Debloating"; } 2>/dev/null
exec_script ${SETUP_DIR}/02-deblaot.sh
ostree container commit

{ enclosed_heading_this "Preparing System Environment"; } 2>/dev/null
exec_script ${SETUP_DIR}/03-prep-env.sh
ostree container commit

{ enclosed_heading_this "Copying Over System Default Files"; } 2>/dev/null
exec_script ${SETUP_DIR}/04-copy-files.sh
ostree container commit

{ enclosed_heading_this "Updating And Installing Packages"; } 2>/dev/null
exec_script ${SETUP_DIR}/05-rpm-pkgs.sh
ostree container commit

{ enclosed_heading_this "Applying Themes On Various System Components"; } 2>/dev/null
exec_script ${SETUP_DIR}/07-theming.sh
ostree container commit

{ enclosed_heading_this "Enhancing Security With Secatcat"; } 2>/dev/null
exec_script ${SETUP_DIR}/08-secatcat.sh
ostree container commit

{ enclosed_heading_this "Configuring Systemd Services"; } 2>/dev/null
exec_script ${SETUP_DIR}/09-systemd.sh
ostree container commit

{ enclosed_heading_this "Refining System With Tweaks And Fixes"; } 2>/dev/null
exec_script ${SETUP_DIR}/10-tweaks-and-fixes.sh
ostree container commit

{ enclosed_heading_this "Applying Branding"; } 2>/dev/null
exec_script ${SETUP_DIR}/11-image-info.sh
ostree container commit

{ enclosed_heading_this "Configuring Signing Policy"; } 2>/dev/null
exec_script ${SETUP_DIR}/12-signing.sh
ostree container commit

{ enclosed_heading_this "Regenerating Initramfs"; } 2>/dev/null
exec_script ${SETUP_DIR}/13-initramfs.sh
ostree container commit

{ enclosed_heading_this "Post Build Setup"; } 2>/dev/null
exec_script ${SETUP_DIR}/14-post-setup.sh
ostree container commit
