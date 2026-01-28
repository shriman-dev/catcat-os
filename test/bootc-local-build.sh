#!/usr/bin/bash
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_DIR="$(dirname ${SCRIPT_DIR})"
source "${REPO_DIR}"/ENVAR

PROJECT_NAME="origami"
IMAGE_NAME="origami"
BASE_IMAGE_URL="ghcr.io/blue-build/base-images/fedora-cosmic"
PUSH_REGISTRY="registry.gitlab.com/origami-linux/images" # This script does not push built image
ALT_TAG="main"

LABELS=(
        "--label" "org.opencontainers.image.created=$(date +%Y\-%m\-%d\T%H\:%M\:%S\Z)"
        "--label" "org.opencontainers.image.description=none"
        "--label" "org.opencontainers.image.title=${IMAGE_NAME}"
        "--label" "org.opencontainers.image.vendor=${IMAGE_NAME}"
        "--label" "org.opencontainers.image.version=${MAJOR_VERSION}.${DATESTAMP}.${TIMESTAMP}"
        "--label" "containers.bootc=1"
)


BUILD_ARGS=(
        "--build-arg" "PROJECT_NAME=${PROJECT_NAME}"
        "--build-arg" "IMAGE_NAME=${IMAGE_NAME}"
        "--build-arg" "BASE_IMAGE_URL=${BASE_IMAGE_URL}"
        "--build-arg" "PUSH_REGISTRY=${PUSH_REGISTRY}"
        "--build-arg" "MAJOR_VERSION=${MAJOR_VERSION}"
        "--build-arg" "ALT_TAG=${ALT_TAG}"
        "--build-arg" "TAG_VER=${MAJOR_VERSION}"
        "--build-arg" "DATESTAMP=${DATESTAMP}"
        "--build-arg" "TIMESTAMP=${TIMESTAMP}"
        "--build-arg" "COMMIT_SHA=${COMMIT_SHA-$(git rev-parse HEAD)}"
)

podman build "${BUILD_ARGS[@]}" "${LABELS[@]}" \
            --tag localhost/local-build:"${DEFAULT_TAG}" \
            --file "${REPO_DIR}"/Containerfile .


#buildah build "${BUILD_ARGS[@]}" "${LABELS[@]}" \
#            --tag ${DEFAULT_TAG} \
#            --format docker \
#            --tls-verify=true \
#            --file Containerfile .
