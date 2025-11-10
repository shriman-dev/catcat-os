#!/usr/bin/env bash
set -oue pipefail
SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

enclosed_heading "Building CatCat OS Image: ${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP}, From Commit: ${COMMIT_SHA}" "" "120"

enclosed_heading "Cleaning Up"
${SETUP_DIR}/cleanup.sh

enclosed_heading "Debloating"
${SETUP_DIR}/deblaot.sh

enclosed_heading "Preparing System Environment"
${SETUP_DIR}/prep-sys-env.sh

enclosed_heading "Copying Over System Default Files"
${SETUP_DIR}/copy-sys-files.sh

enclosed_heading "Applying Branding"
${SETUP_DIR}/branding.sh

enclosed_heading "Installing RPM Packages"
${SETUP_DIR}/rpm-ostree-pkgs.sh

enclosed_heading "Installing Extra External Packages"
${SETUP_DIR}/extra-extrn-pkgs.sh

enclosed_heading "Refining System With Tweaks And Fixes"
${SETUP_DIR}/tweaks-and-fixes.sh

enclosed_heading "Applying Themes On Various Components Of System"
${SETUP_DIR}/config-themes.sh

enclosed_heading "Enhance Security With Secatcat"
$SCRIPT_DIR/secatcat.sh

enclosed_heading "Configuring Systemd Services"
${SETUP_DIR}/systemd.sh

enclosed_heading "Regenerate Initramfs"
${SETUP_DIR}/initramfs.sh

enclosed_heading "Configuring Signing Policy"
${SETUP_DIR}/signing.sh






