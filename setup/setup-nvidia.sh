#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"
STAGE="${IMG_FLAVOR^^}: "

"${BUILD_SETUP_DIR}/shared/00-setup-base.sh"

setup_heading "Build Stage - ${STAGE%:*} | Image - ${IMAGE_NAME}:${IMG_FLAVOR}"

#run_step "blue" "Cleaning Up" \
#         "${BUILD_SETUP_DIR}/nvidia/01-cleanup.sh"

run_step "yellow" "Debloating" \
         "${BUILD_SETUP_DIR}/nvidia/02-debloat.sh"

run_step "cyan" "Installing NVIDIA Packages" \
         "${BUILD_SETUP_DIR}/nvidia/04-pkgs-install.sh"

run_step "purple" "Copying System Default Files" \
         "${BUILD_SETUP_DIR}/nvidia/03-copy-sysfiles.sh"

#run_step "green" "Applying Various Themes" \
#         "${BUILD_SETUP_DIR}/nvidia/05-theming.sh"

#run_step "blue" "Enhancing Security" \
#         "${BUILD_SETUP_DIR}/nvidia/06-secatcat.sh"

run_step "yellow" "Configuring Systemd Services" \
         "${BUILD_SETUP_DIR}/nvidia/07-systemd.sh"

run_step "cyan" "Tweaks And Fixes" \
         "${BUILD_SETUP_DIR}/nvidia/08-tweaks-fixes.sh"

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
