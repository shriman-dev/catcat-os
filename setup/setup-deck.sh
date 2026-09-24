#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"

"${BUILD_SETUP_DIR}/shared/00-setup-base.sh"

STAGE="${IMG_FLAVOR^^}: "
#run_step "blue" "Cleaning Up" \
#         "${BUILD_SETUP_DIR}/deck/01-cleanup.sh"

#run_step "yellow" "Debloating" \
#         "${BUILD_SETUP_DIR}/deck/02-debloat.sh"

run_step "cyan" "Copying System Default Files" \
         "${BUILD_SETUP_DIR}/deck/03-copy-sysfiles.sh"

run_step "yellow" "Installing Deck Packages" \
         "${BUILD_SETUP_DIR}/deck/04-pkgs-install.sh"

#run_step "cyan" "Applying Various Themes" \
#         "${BUILD_SETUP_DIR}/deck/05-theming.sh"

run_step "purple" "Enhancing Security" \
         "${BUILD_SETUP_DIR}/deck/06-secatcat.sh"

run_step "green" "Configuring Systemd Services" \
         "${BUILD_SETUP_DIR}/deck/07-systemd.sh"

run_step "blue" "Tweaks And Fixes" \
         "${BUILD_SETUP_DIR}/deck/08-tweaks-fixes.sh"

run_step "cyan" "Applying Image Info" \
         "${BUILD_SETUP_DIR}/shared/02-image-info.sh"

run_step "purple" "Signing Image Container and Kernel" \
         "${BUILD_SETUP_DIR}/shared/03-signing.sh"

run_step "green" "Regenerating Initramfs" \
         "${BUILD_SETUP_DIR}/shared/04-initramfs.sh"

run_step "blue" "Post Build Setup" \
         "${BUILD_SETUP_DIR}/shared/05-post-setup.sh"

set -x
ostree container commit
