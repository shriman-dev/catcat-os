#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

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

for key in "${!pairs[@]}"; do
    value="${pairs[${key}]}"
    log "DEBUG" "${key}=${value}"
    replace_add "${key}=" "${key}=\"${value}\"" /usr/lib/os-release
done
log "INFO" "Applied."

log "INFO" "Full output of os-release file: ${IMPORT_FILE}"
cat /usr/lib/os-release
