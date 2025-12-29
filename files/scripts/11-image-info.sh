#!/usr/bin/env bash
source /usr/lib/catcat/funcvar.sh
set -ouex pipefail

OS_RELEASE_FILE="/usr/lib/os-release"

log "INFO" "Applying custom OS labels"
declare -A pairs=(
    ["NAME"]="CatCat OS"
    ["PRETTY_NAME"]="CatCat OS ${MAJOR_VERSION}"
    ["ID"]="catcat"
    ["ID_LIKE"]="fedora"
    ["IMAGE_ID"]="${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP}"
    ["VARIANT_ID"]="${IMAGE_NAME}"
    ["BOOTLOADER_NAME"]="CatCat OS ${MAJOR_VERSION} (${DATESTAMP})"
    ["DEFAULT_HOSTNAME"]="catcat"
)
# Iterate over the key-value pairs
for key in "${!pairs[@]}"; do
    value="${pairs[${key}]}"
    log "DEBUG" "${key}=${value}"
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "${OS_RELEASE_FILE}"
    # If the key does not exist, append it to the os-release file
    grep -q "^${key}=" "${OS_RELEASE_FILE}" || echo "${key}=\"${value}\"" >> "${OS_RELEASE_FILE}"
done
log "INFO" "Applied."

log "INFO" "Full output of: ${OS_RELEASE_FILE}"
cat "${OS_RELEASE_FILE}"
