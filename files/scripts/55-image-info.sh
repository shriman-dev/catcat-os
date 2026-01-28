#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail
log "INFO" "Applying custom image info and labels"

declare -A IMAGE_INFO=(
    ["NAME"]="CatCat OS"
    ["PRETTY_NAME"]="CatCat OS ${MAJOR_VERSION}"
    ["ID"]="${PROJECT_NAME}"
    ["ID_LIKE"]="fedora"
    ["IMAGE_ID"]="${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP}"
    ["VARIANT_ID"]="${IMAGE_NAME}${ALT_TAG:+:${ALT_TAG}}"
    ["BOOTLOADER_NAME"]="CatCat OS ${MAJOR_VERSION} (${DATESTAMP})"
    ["DEFAULT_HOSTNAME"]="catcat"
)


OS_RELEASE_FILE="/usr/lib/os-release"
# Iterate over IMAGE_INFO key-value pairs
for key in "${!IMAGE_INFO[@]}"; do
    value="${IMAGE_INFO[${key}]}"
    log "DEBUG" "${key}=${value}"
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "${OS_RELEASE_FILE}"
    # If the key does not exist, append it to the os-release file
    grep -q "^${key}=" "${OS_RELEASE_FILE}" || echo "${key}=\"${value}\"" >> "${OS_RELEASE_FILE}"
done
log "INFO" "Applied."

log "INFO" "Full output of: ${OS_RELEASE_FILE}"
cat "${OS_RELEASE_FILE}"
