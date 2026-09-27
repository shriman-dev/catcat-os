#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"
STAGE="BASE: "

# Set build status
[[ -d "/etc/${PROJECT_NAME}" ]] && echo "1" > "/run/CURRENT_PROJECT"
[[ -d "${BUILD_CACHE_DIR}" ]] && echo "1" > "/run/REBUILDING_IMAGE"

setup_heading "Build Stage - ${STAGE%:*} | Image - ${IMAGE_NAME}:${IMG_FLAVOR}"

run_step "green" "Preparing System Environment" \
         "${BUILD_SETUP_DIR}/shared/01-prep-env.sh"


# Exit when image is being re/built on base image of current project
[[ -f "/run/CURRENT_PROJECT" ]] && exit 0


run_step "blue" "Cleaning Up" \
         "${BUILD_SETUP_DIR}/main/01-cleanup.sh"

run_step "yellow" "Debloating" \
         "${BUILD_SETUP_DIR}/main/02-debloat.sh"

run_step "cyan" "Copying System Default Files" \
         "${BUILD_SETUP_DIR}/main/03-copy-sysfiles.sh"

run_step "purple" "Adding Kernel Packages" \
         "${BUILD_SETUP_DIR}/main/04-pkgs-install.sh"

run_step "green" "Applying Various Themes" \
         "${BUILD_SETUP_DIR}/main/05-theming.sh"

run_step "blue" "Enhancing Security" \
         "${BUILD_SETUP_DIR}/main/06-secatcat.sh"

run_step "yellow" "Configuring Systemd Services" \
         "${BUILD_SETUP_DIR}/main/07-systemd.sh"

run_step "cyan" "Tweaks And Fixes" \
         "${BUILD_SETUP_DIR}/main/08-tweaks-fixes.sh"
