#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"
STAGE="${IMG_FLAVOR^^}: "

"${BUILD_SETUP_DIR}/shared/00-setup-base.sh"

setup_heading "Build Stage - ${STAGE%:*} | Image - ${IMAGE_NAME}:${IMG_FLAVOR}"

run_step "purple" "Applying Image Info" \
         "${BUILD_SETUP_DIR}/shared/02-image-info.sh"

run_step "green" "Signing Image Container and Kernel" \
         "${BUILD_SETUP_DIR}/shared/03-signing.sh"

run_step "blue" "Regenerating Initramfs" \
         "${BUILD_SETUP_DIR}/shared/04-initramfs.sh"

run_step "yellow" "Post Build Setup" \
         "${BUILD_SETUP_DIR}/shared/05-post-setup.sh"

set -x
ostree container commit
