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
    local color="${1}" heading="${2}" script="${3}"; shift 3
    local args=("$@")

    enclosed_heading "${heading}" "=" "100" "${color}"
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
            run_step "yellow" "Preparing System Environment" \
            "${BUILD_SETUP_DIR}/01-prep-env.sh"
            ;;
        cleanup)
            run_step "blue" "Cleaning Up" \
            "${BUILD_SETUP_DIR}/02-cleanup.sh"
            ;;
        debloat)
            run_step "red" "Debloating" \
            "${BUILD_SETUP_DIR}/03-debloat.sh"
            ;;
        copy-sysfiles)
            run_step "green" "Copying System Default Files" \
            "${BUILD_SETUP_DIR}/04-copy-sysfiles.sh"
            ;;
        pkgs-kernel)
            run_step "yellow" "Adding Kernel Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-start" "kernel"
            ;;
        pkgs-common)
            run_step "yellow" "Installing Common Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "common"
            ;;
        pkgs-hwaccel)
            run_step "yellow" "Installing HW Acceleration Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "hwaccel"
            ;;
        pkgs-desktop)
            run_step "yellow" "Installing Desktop Packages" \
            "${BUILD_SETUP_DIR}/05-pkgs-install.sh" "batch-end" "desktop"
            ;;
        theming)
            run_step "blue" "Applying Various Themes" \
            "${BUILD_SETUP_DIR}/06-theming.sh"
            ;;
        secatcat)
            run_step "red" "Enhancing Security" \
            "${BUILD_SETUP_DIR}/07-secatcat.sh"
            ;;
        systemd)
            run_step "green" "Configuring Systemd Services" \
            "${BUILD_SETUP_DIR}/08-systemd.sh"
            ;;
        tweaks-fixes)
            run_step "cyan" "Tweaks And Fixes" \
            "${BUILD_SETUP_DIR}/09-tweaks-fixes.sh"
            ;;
        variants)
            if [[ "${ALT_TAG}" != "main" ]]; then
                run_step "yellow" "Building ${ALT_TAG^} Image" \
                "${BUILD_SETUP_DIR}/setup-${ALT_TAG}.sh"
            fi
            ;;
        image-info)
            run_step "blue" "Applying Image Info" \
            "${BUILD_SETUP_DIR}/10-image-info.sh"
            ;;
        signing)
            run_step "red" "Signing Image Container and Kernel" \
            "${BUILD_SETUP_DIR}/11-signing.sh"
            ;;
        initramfs)
            run_step "green" "Regenerating Initramfs" \
            "${BUILD_SETUP_DIR}/12-initramfs.sh"
            ;;
        post-setup)
            run_step "cyan" "Post Build Setup" \
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

if [[ ${STEP_SKIPPED:-} != true ]]; then
    after_cleanup
    set -x; ostree container commit
fi
