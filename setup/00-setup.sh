#!/usr/bin/env bash
set -euo pipefail
umask 0022
source "${BUILD_SCRIPT_LIB}"

# This is useful when rebuilding image or caching
declare -x BUILD_CACHE_DIR="/var/cache/${PROJECT_NAME}"
build_markd="/var/build_markd"

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
    local heading="${1}"
    local script="${2}"
    shift 2
    local args=("$@")

    enclosed_heading "${heading}" "=" "100"
    if [[ -n "${args[@]}" ]]; then
        ( set -x; "${script}" "${args[@]}" )
    else
        ( set -x; "${script}" )
    fi
}

steps() {
    local arg="${1}"

    # Skip below steps when building on base image of current project
    if [[ -f "${build_markd}/CURRENT_PROJECT" ]]; then
        STEP_SKIPPED=true
        case "${arg}" in
            cleanup|debloat|copy-sysfiles|pkgs-*|theming|secatcat|systemd|tweaks-fixes)
                return 0
                ;;
        esac
    fi

    case "${arg}" in
        prep-env)
            run_step "Preparing System Environment" \
            "${BUILD_SETUP_DIR}/01-prep-env.sh"
            ;;
        cleanup)
            run_step "Cleaning Up" \
            "${BUILD_SETUP_DIR}/02-cleanup.sh"
            ;;
        debloat) # Corrected typo from deblaot
            run_step "Debloating" \
            "${BUILD_SETUP_DIR}/03-debloat.sh"
            ;;
        copy-sysfiles)
            run_step "Copying System Default Files" \
            "${BUILD_SETUP_DIR}/04-copy-sysfiles.sh"
            ;;
        pkgs-kernel)
            run_step "Adding Kernel Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-start" "kernel"
            ;;
        pkgs-common)
            run_step "Installing Common Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "common"
            ;;
        pkgs-desktop)
            run_step "Installing Desktop Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-end" "desktop"
            ;;
        theming)
            run_step "Applying Various Themes" \
            "${BUILD_SETUP_DIR}/07-theming.sh"
            ;;
        secatcat)
            run_step "Enhancing Security" \
            "${BUILD_SETUP_DIR}/08-secatcat.sh"
            ;;
        systemd)
            run_step "Configuring Systemd Services" \
            "${BUILD_SETUP_DIR}/09-systemd.sh"
            ;;
        tweaks-fixes)
            run_step "Tweaks And Fixes" \
            "${BUILD_SETUP_DIR}/10-tweaks-fixes.sh"
            ;;
        build-variants)
            if [[ "${IMAGE_NAME}" =~ "-nv" ]]; then
                run_step "Building NVIDIA Image" \
                "${BUILD_SETUP_DIR}/build-nvidia.sh"
            fi
            if [[ "${IMAGE_NAME}" =~ "-hh" ]]; then
                run_step "Building Deck Image" \
                "${BUILD_SETUP_DIR}/build-deck.sh"
            fi
            ;;
        image-info)
            run_step "Applying Image Info" \
            "${BUILD_SETUP_DIR}/11-image-info.sh"
            ;;
        signing)
            run_step "Signing Image Container and Kernel" \
            "${BUILD_SETUP_DIR}/12-signing.sh"
            ;;
        initramfs)
            run_step "Regenerating Initramfs" \
            "${BUILD_SETUP_DIR}/13-initramfs.sh"
            ;;
        post-setup)
            run_step "Post Build Setup" \
            "${BUILD_SETUP_DIR}/14-post-setup.sh"
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

if [[ ${STEP_SKIPPED:-} != true ]]; then
    after_cleanup
    set -x; ostree container commit
fi
