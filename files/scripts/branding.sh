#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh
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
    sed -i "s/^${key}=.*/${key}=\"${value}\"/" "${OS_RELEASE_FILE}"
    # If the key does not exist, append it to the os-release file
    if ! grep -q "^${key}=" "${OS_RELEASE_FILE}"; then
        echo "${key}=\"${value}\"" | tee -a "${OS_RELEASE_FILE}" >/dev/null
    fi
done
log "INFO" "Applied."

log "INFO" "Full output of os-release file: /usr/lib/os-release"
cat "${OS_RELEASE_FILE}"
