#!/usr/bin/env bash
set -euo pipefail
umask 0022
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$(dirname ${SCRIPT_DIR})/files/scripts/script_lib/funcvar.sh"
source "${SCRIPT_DIR}/ENVAR"

while [[ $# -gt 0 ]]; do
    case ${1} in
        --image-name)  declare -x IMAGE_NAME="${2}"; shift  ;;
        --base-image)  declare -x BASE_IMAGE="${2}"; shift  ;;
        --alt-tag)     declare -x ALT_TAG="${2}"   ; shift  ;;
        *)             die "Unknown option: ${1}";;
    esac
    shift
done

LOG_FILE="${SCRIPT_DIR}/.log/${IMAGE_NAME}/${IMAGE_NAME}.${DATETIMESTAMP}.log"
mkdir -p "$(dirname ${LOG_FILE})"
{
    symmetric_heading "#" "#" "100"
    echo " Building    - ${IMAGE_NAME}:${ALT_TAG}"
    echo " Base Image  - ${BASE_IMAGE}"
    echo " Datestamp   - ${DATETIMESTAMP}"
    echo " Git Commit  - ${COMMIT_SHA}"
    echo " Working Dir - ${SCRIPT_DIR}"
    symmetric_heading "#" "#" "100"

    _cmd_test_timer_start=$(date +%s)
    podman-compose --verbose \
                   --project-name "${PROJECT_NAME}" \
                   --file "${SCRIPT_DIR}"/build.yml build
    symmetric_heading "#" "#" "100"
    echo " Build Done  - ${IMAGE_NAME}:${ALT_TAG}"
    echo " Build Time  - $(cmd_test_timer)"
    symmetric_heading "#" "#" "100"
} \
2>&1 | while read -r line ; do echo "$(date +'[%T.%3N]') ${line}"; done \
2>&1 | tee -a "${LOG_FILE}"





