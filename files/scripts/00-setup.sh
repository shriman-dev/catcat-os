#!/usr/bin/env bash
set -oue pipefail
export BUILD_SETUP_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export BUILD_SCRIPT_LIB="${BUILD_SETUP_DIR}/funcvar.sh"
source ${BUILD_SCRIPT_LIB}

enclosed_heading_this() {
    local text="${1}" padding_char="${2:-=}" output_width=${3:-120}
    enclosed_heading "${text}" "${padding_char}" ${output_width}
}

exec_script() {
    {
        local script="${1}"
        sed -E '/log ("DEBUG"|"INFO")/ s/$/; } 2>\/dev\/null/' "${script}" | \
        sed -Ee 's|log "INFO"|{ log "INFO"|g' \
            -e 's|log "DEBUG"|{ log "DEBUG"|g'
    } 2>/dev/null | bash -s -- "${@:2}"
}

export -f exec_script

enclosed_heading_this "Building CatCat OS Image: ${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP} | With Commit: ${COMMIT_SHA}" "#"

declare -A STEPS=(
    ["Cleaning Up"]="\
01-cleanup.sh"

    ["Debloating"]="\
02-deblaot.sh"

    ["Preparing System Environment"]="\
03-prep-env.sh"

    ["Copying Over System Default Files"]="\
04-copy-files.sh"

    ["Updating And Installing Packages"]="\
05-install-pkgs.sh"

    ["Applying Various Themes"]="\
07-theming.sh"

    ["Enhancing Security With Secatcat"]="\
08-secatcat.sh"

    ["Configuring Systemd Services"]="\
10-systemd.sh"

    ["Refining System With Tweaks And Fixes"]="\
11-tweaks-and-fixes.sh"

    ["Applying Image Info"]="\
55-image-info.sh"

    ["Configuring Signing Policy"]="\
56-signing.sh"

    ["Regenerating Initramfs"]="\
57-initramfs.sh"

    ["Post Build Setup"]="\
58-post-setup.sh"
)

set -x
for heading in "${!STEPS[@]}"; do
    step_script="${STEPS[${heading}]}"
    { enclosed_heading_this "${heading}"; } 2>/dev/null
    exec_script "${BUILD_SETUP_DIR}/${step_script}"
    ostree container commit
done
