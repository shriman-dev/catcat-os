#!/usr/bin/env bash
set -oue pipefail
export SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SETUP_DIR}/funcvar.sh

echo "$(curl -s -X GET https://api.github.com/repos/watchexec/watchexec/releases/latest | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.rpm"' | cut -d'"' -f4)"

enclosed_heading_this() {
    local text="${1}" padding_char="${2:-=}" output_width=${3:-120}
    enclosed_heading "${text}" "${padding_char}" ${output_width}
}

enclosed_heading_this "Building CatCat OS Image: ${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP} | With Commit: ${COMMIT_SHA}" "#"

enclosed_heading_this "Cleaning Up"
${SETUP_DIR}/01-cleanup.sh

enclosed_heading_this "Debloating"
${SETUP_DIR}/02-deblaot.sh

enclosed_heading_this "Preparing System Environment"
${SETUP_DIR}/03-prep-env.sh

enclosed_heading_this "Copying Over System Default Files"
${SETUP_DIR}/04-copy-files.sh

enclosed_heading_this "Updating And Installing Packages"
${SETUP_DIR}/05-rpm-pkgs.sh

enclosed_heading_this "Applying Themes On Various System Components"
${SETUP_DIR}/07-theming.sh

enclosed_heading_this "Enhancing Security With Secatcat"
${SETUP_DIR}/08-secatcat.sh

enclosed_heading_this "Configuring Systemd Services"
${SETUP_DIR}/09-systemd.sh

enclosed_heading_this "Refining System With Tweaks And Fixes"
${SETUP_DIR}/10-tweaks-and-fixes.sh

enclosed_heading_this "Applying Branding"
${SETUP_DIR}/11-image-info.sh

enclosed_heading_this "Configuring Signing Policy"
${SETUP_DIR}/12-signing.sh

enclosed_heading_this "Regenerating Initramfs"
${SETUP_DIR}/13-initramfs.sh

enclosed_heading_this "Post Build Cleaning"
${SETUP_DIR}/14-post-setup.sh

ostree -v container commit
