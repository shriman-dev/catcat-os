#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"

setup_heading "Build Image - ${IMAGE_NAME}:${IMG_FLAVOR}"

run_step "green" "Preparing System Environment" \
         "${BUILD_SETUP_DIR}/shared/01-prep-env.sh"

run_step "blue" "Cleaning Up" \
         "${BUILD_SETUP_DIR}/main/01-cleanup.sh"

run_step "yellow" "Debloating" \
         "${BUILD_SETUP_DIR}/main/02-debloat.sh"

run_step "cyan" "Copying System Default Files" \
         "${BUILD_SETUP_DIR}/main/03-copy-sysfiles.sh"

run_step "purple" "Adding Kernel Packages" \
         "${BUILD_SETUP_DIR}/main/04-pkgs-install.sh" "batch-start" "kernel"

run_step "green" "Installing Common Packages" \
         "${BUILD_SETUP_DIR}/main/04-pkgs-install.sh" "common"

run_step "blue" "Installing HW Acceleration Packages" \
         "${BUILD_SETUP_DIR}/main/04-pkgs-install.sh" "hwaccel"

run_step "yellow" "Installing Desktop Packages" \
         "${BUILD_SETUP_DIR}/main/04-pkgs-install.sh" "batch-end" "desktop"

run_step "cyan" "Applying Various Themes" \
         "${BUILD_SETUP_DIR}/main/05-theming.sh"

run_step "purple" "Enhancing Security" \
         "${BUILD_SETUP_DIR}/main/06-secatcat.sh"

run_step "green" "Configuring Systemd Services" \
         "${BUILD_SETUP_DIR}/main/07-systemd.sh"

run_step "blue" "Tweaks And Fixes" \
         "${BUILD_SETUP_DIR}/main/08-tweaks-fixes.sh"

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
