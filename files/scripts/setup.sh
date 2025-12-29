#!/usr/bin/env bash
set -oue pipefail
export SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

enclosed_heading_this() {
    local text="${1}" padding_char="${2:-=}" output_width=${3:-120}
    enclosed_heading "${text}" "${padding_char}" ${output_width}
}

enclosed_heading_this "Building CatCat OS Image: ${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP} | With Commit: ${COMMIT_SHA}" "#"

enclosed_heading_this "Cleaning Up"
${SETUP_DIR}/cleanup.sh

enclosed_heading_this "Debloating"
${SETUP_DIR}/deblaot.sh

enclosed_heading_this "Preparing System Environment"
${SETUP_DIR}/prep-sys-env.sh

enclosed_heading_this "Copying Over System Default Files"
${SETUP_DIR}/copy-sys-files.sh

enclosed_heading_this "Updating And Installing Packages"
${SETUP_DIR}/rpm-ostree-pkgs.sh

enclosed_heading_this "Applying Themes On Various System Components"
${SETUP_DIR}/config-themes.sh

enclosed_heading_this "Enhancing Security With Secatcat"
${SETUP_DIR}/secatcat.sh

enclosed_heading_this "Configuring Systemd Services"
${SETUP_DIR}/systemd.sh

enclosed_heading_this "Refining System With Tweaks And Fixes"
${SETUP_DIR}/tweaks-and-fixes.sh

enclosed_heading_this "Applying Branding"
${SETUP_DIR}/branding.sh

enclosed_heading_this "Configuring Signing Policy"
${SETUP_DIR}/signing.sh

enclosed_heading_this "Regenerating Initramfs"
${SETUP_DIR}/initramfs.sh

enclosed_heading_this "Post Build Cleaning"
${SETUP_DIR}/post-cleanup.sh
