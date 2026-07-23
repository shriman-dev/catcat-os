#!/usr/bin/env bash
set -euo pipefail
umask 0022
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$(dirname ${SCRIPT_DIR})/files/scripts/script_lib/funcvar.sh"

declare -xr PRETTY_NAME="CatCat OS"
declare -xr PROJECT_NAME="catcat-os"
declare -xr PROJECT_DESC="Meow"
declare -xr DEFAULT_TAG="latest"
declare -xr MAJOR_VERSION=44
declare -xr PUSH_REGISTRY="ghcr.io/shriman-dev"
declare -xr CUSTOM_KERNEL="kernel-cachyos"
declare -xr DATESTAMP="$(date "+%Y%m%d")"
declare -xr TIMESTAMP="$(date "+%H%M%S")"
declare -xr DATETIMESTAMP="${DATESTAMP}.${TIMESTAMP}"
declare -xr TIMEZONE="$(timedatectl show -p Timezone --value)"
declare -xr AH_DATE="$(date +%Y\-%m\-%d\T%H\:%M\:%S\Z)"
declare -xr COMMIT_SHA="$(git rev-parse HEAD)"


while [[ $# -gt 0 ]]; do
    case ${1} in
        --image-name)  declare -xr IMAGE_NAME="${2}"; shift ;;
        --base-image)  declare -xr BASE_IMAGE="${2}"; shift ;;
        --alt-tag)     declare -xr ALT_TAG="${2}"   ; shift ;;
        *)             die "Unknown option: ${1}"           ;;
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





