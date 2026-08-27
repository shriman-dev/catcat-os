#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"

# This is useful when rebuilding image or caching
declare -x BUILD_CACHE_DIR="/var/cache/${PROJECT_NAME}"
build_markd="/var/build_markd"

# Check first setup run; if yes
# Track image is being rebuilt with file REBUILDING_IMAGE
# Track image is being re/built on base image of current project with file CURRENT_PROJECT
mkdir -p "${BUILD_CACHE_DIR}" "${build_markd}"
if [[ ! -f "${build_markd}/marked" ]]; then
    mkdir -p "${build_markd}"

    [[ -d "${BUILD_CACHE_DIR}" ]] &&
        echo "1" > "${build_markd}/REBUILDING_IMAGE"
    [[ -d "/etc/${PROJECT_NAME}" ]] &&
        echo "1" > "${build_markd}/CURRENT_PROJECT"

    echo "1" > "${build_markd}/marked"
fi

run_step() {
    local color="${1}" heading="${2}" script="${3}"; shift 3
    local args=("$@")

    enclosed_heading "${heading}" "=" "100" "${color}"
    if [[ -n "${args[*]}" ]]; then
        ( set -x; "${script}" "${args[@]}" )
    else
        ( set -x; "${script}" )
    fi
}

steps() {
    local arg="${1}"
    local skip_list="cleanup|debloat|copy-sysfiles|pkgs-|theming|secatcat|systemd|tweaks-fixes"

    if [[ "${ALT_TAG}" == "main" && "${arg}" == "variant" ]]; then
        # Skip "variant" step when it's main image
        STEP_SKIPPED=1
        return 0
    elif [[ -f "${build_markd}/CURRENT_PROJECT" && "${arg}" =~ ^(${skip_list}) ]]; then
        # Skip the steps when building on base image of current project
        STEP_SKIPPED=1
        return 0
    fi

    case "${arg}" in
        prep-env)
            run_step "green" "Preparing System Environment" \
            "${BUILD_SETUP_DIR}/01-prep-env.sh"
            ;;
        cleanup)
            run_step "blue" "Cleaning Up" \
            "${BUILD_SETUP_DIR}/02-cleanup.sh"
            ;;
        debloat)
            run_step "yellow" "Debloating" \
            "${BUILD_SETUP_DIR}/03-debloat.sh"
            ;;
        copy-sysfiles)
            run_step "cyan" "Copying System Default Files" \
            "${BUILD_SETUP_DIR}/04-copy-sysfiles.sh"
            ;;
        pkgs-kernel)
            run_step "purple" "Adding Kernel Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-start" "kernel"
            ;;
        pkgs-common)
            run_step "green" "Installing Common Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "common"
            ;;
        pkgs-hwaccel)
            run_step "blue" "Installing HW Acceleration Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "hwaccel"
            ;;
        pkgs-desktop)
            run_step "yellow" "Installing Desktop Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-end" "desktop"
            ;;
        theming)
            run_step "cyan" "Applying Various Themes" \
            "${BUILD_SETUP_DIR}/06-theming.sh"
            ;;
        secatcat)
            run_step "purple" "Enhancing Security" \
            "${BUILD_SETUP_DIR}/07-secatcat.sh"
            ;;
        systemd)
            run_step "green" "Configuring Systemd Services" \
            "${BUILD_SETUP_DIR}/08-systemd.sh"
            ;;
        tweaks-fixes)
            run_step "blue" "Tweaks And Fixes" \
            "${BUILD_SETUP_DIR}/09-tweaks-fixes.sh"
            ;;
        variant)
            run_step "yellow" "Building ${ALT_TAG^} Image" \
            "${BUILD_SETUP_DIR}/setup-${ALT_TAG}.sh"
            ;;
        image-info)
            run_step "cyan" "Applying Image Info" \
            "${BUILD_SETUP_DIR}/10-image-info.sh"
            ;;
        signing)
            run_step "purple" "Signing Image Container and Kernel" \
            "${BUILD_SETUP_DIR}/11-signing.sh"
            ;;
        initramfs)
            run_step "green" "Regenerating Initramfs" \
            "${BUILD_SETUP_DIR}/12-initramfs.sh"
            ;;
        post-setup)
            run_step "blue" "Post Build Setup" \
            "${BUILD_SETUP_DIR}/13-post-setup.sh"
            ;;
        *)
            die "Unknown argument: ${arg}"
            ;;
    esac
}

if [[ $# -eq 0 ]]; then
    die "No argument provided"
fi

for arg in "$@"; do
    steps "${arg}"
done

if [[ ${STEP_SKIPPED:-0} -ne 1 ]]; then
    after_cleanup
    set -x; ostree container commit
fi
