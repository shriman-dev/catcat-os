#!/usr/bin/env bash
set -euo pipefail
umask 0022
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$(dirname ${SCRIPT_DIR})/files/scripts/script_lib/funcvar.sh"
source "${SCRIPT_DIR}/ENVAR"

while [[ $# -gt 0 ]]; do
    case ${1} in
        --image-name)  IMAGE_NAME="${2}"; shift  ;;
        --base-image)  BASE_IMAGE="${2}"; shift  ;;
        --alt-tag)     ALT_TAG="${2}"   ; shift  ;;
        *)             die "Unknown option: ${1}";;
    esac
    shift
done

BUILD_ARGS=(
    "--build-arg" "PRETTY_NAME=${PRETTY_NAME}"
    "--build-arg" "PROJECT_NAME=${PROJECT_NAME}"
    "--build-arg" "PROJECT_VENDOR=${PROJECT_VENDOR}"
    "--build-arg" "PROJECT_SOURCE=${PROJECT_SOURCE}"
    "--build-arg" "PROJECT_README=${PROJECT_README}"
    "--build-arg" "PUSH_REGISTRY=${PUSH_REGISTRY}"
    "--build-arg" "MAJOR_VERSION=${MAJOR_VERSION}"
    "--build-arg" "CUSTOM_KERNEL=${CUSTOM_KERNEL}"
    "--build-arg" "TIMEZONE=${TIMEZONE}"
    "--build-arg" "DATESTAMP=${DATESTAMP}"
    "--build-arg" "TIMESTAMP=${TIMESTAMP}"
    "--build-arg" "COMMIT_SHA=${COMMIT_SHA}"
    "--build-arg" "IMAGE_NAME=${IMAGE_NAME}"
    "--build-arg" "BASE_IMAGE=${BASE_IMAGE}"
    "--build-arg" "ALT_TAG=${ALT_TAG}"
)

BUILD_LABELS=(
    "--label" "io.artifacthub.package.deprecated=false"
    "--label" "io.artifacthub.package.prerelease=false"
    "--label" "io.artifacthub.package.readme-url=${PROJECT_README}"
    "--label" "org.opencontainers.image.documentation=${PROJECT_README}"
    "--label" "org.opencontainers.image.source=${PROJECT_SOURCE}"
    "--label" "org.opencontainers.image.created=${AH_DATE}"
    "--label" "org.opencontainers.image.description=${PROJECT_DESCRP}"
    "--label" "org.opencontainers.image.title=${IMAGE_NAME}"
    "--label" "org.opencontainers.image.vendor=${PROJECT_VENDOR}"
    "--label" "org.opencontainers.image.version=${MAJOR_VERSION}.${DATETIMESTAMP}"
    "--label" "containers.bootc=1"
)

BUILD_TAGS=(
    "--tag" "${IMAGE_NAME}:${DEFAULT_TAG}"
    "--tag" "${IMAGE_NAME}:${MAJOR_VERSION}"
)

EXTRA_TAGS=(
    "--tag" "${IMAGE_NAME}:$(git rev-parse --short HEAD)"
    "--tag" "${IMAGE_NAME}:${MAJOR_VERSION}.${DATESTAMP}"
    "--tag" "${IMAGE_NAME}:${MAJOR_VERSION}.${DATETIMESTAMP}"
    "--tag" "${IMAGE_NAME}:${ALT_TAG}"
    "--tag" "${IMAGE_NAME}:${ALT_TAG}.${DATETIMESTAMP}"
)

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    BUILD_TAGS+=("${EXTRA_TAGS[@]}")
    echo "build_tags=${BUILD_TAGS[@]/--tag/}" >> "${GITHUB_OUTPUT}"
fi

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
    cd "$(dirname ${SCRIPT_DIR})"
    ( set -x; podman build \
                     --pull=newer \
                     --secret "id=sbmok_priv,env=SBMOK_KEY" \
                     --file "Containerfile" \
                     "${BUILD_LABELS[@]}" \
                     "${BUILD_ARGS[@]}" \
                     "${BUILD_TAGS[@]}" \
                     . )
    symmetric_heading "#" "#" "100"
    echo " Build Done  - ${IMAGE_NAME}:${ALT_TAG}"
    echo " Build Time  - $(cmd_test_timer)"
    symmetric_heading "#" "#" "100"
} \
2>&1 | while read -r line ; do echo "$(date +'[%T.%3N]') ${line}"; done \
2>&1 | tee -a "${LOG_FILE}"





