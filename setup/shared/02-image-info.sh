#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Applying custom image info and labels"
MAJOR_VERSION_WORD="$(grep -o '(.*)' /usr/lib/fedora-release)"
PROJECT_SUBNAME="${PROJECT_NAME/-os/}"
declare -A IMAGE_INFO=(
    ["NAME"]="${PRETTY_NAME}"
    ["PRETTY_NAME"]="${PRETTY_NAME} ${MAJOR_VERSION}"
    ["ID"]="${PROJECT_NAME}"
    ["ID_LIKE"]="fedora"
    ["IMAGE_ID"]="${IMAGE_NAME}-${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP}"
    ["VARIANT_ID"]="${IMAGE_NAME}"
    ["LOGO"]="${PROJECT_SUBNAME}-logo-icon"
    ["BOOTLOADER_NAME"]="${PRETTY_NAME} ${MAJOR_VERSION} ${MAJOR_VERSION_WORD}"
    ["DEFAULT_HOSTNAME"]="${PROJECT_SUBNAME}"
    ["CPE_NAME"]="cpe:/o:${PROJECT_SUBNAME}project:${IMAGE_NAME}:${MAJOR_VERSION}"
    ["HOME_URL"]="${PROJECT_SOURCE}"
    ["DOCUMENTATION_URL"]="${PROJECT_README}"
    ["SUPPORT_URL"]="${PROJECT_SOURCE}/issues"
    ["BUG_REPORT_URL"]="${PROJECT_SOURCE}/issues"
)

OS_RELEASE_FILE="/usr/lib/os-release"

for key in "${!IMAGE_INFO[@]}"; do
    value="${IMAGE_INFO[${key}]}"
    log "DEBUG" "${key}=${value}"
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "${OS_RELEASE_FILE}"
    # If the key does not exist, append it to the os-release file
    grep -q "^${key}=" "${OS_RELEASE_FILE}" || echo "${key}=\"${value}\"" >> "${OS_RELEASE_FILE}"
done
sed -i "/^REDHAT_.*=/d" "${OS_RELEASE_FILE}"

echo "${PRETTY_NAME} ${MAJOR_VERSION} ${MAJOR_VERSION_WORD}" > "/usr/lib/fedora-release"
log "INFO" "Applied image info"

log "INFO" "Full output of: ${OS_RELEASE_FILE}"
cat "${OS_RELEASE_FILE}"
