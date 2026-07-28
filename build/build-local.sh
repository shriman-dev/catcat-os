#!/usr/bin/bash
set -euo pipefail
umask 0022
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$(dirname ${SCRIPT_DIR})/setup/setup_lib/funcvar.sh"
source "${SCRIPT_DIR}/ENVAR"

#set -x

BUILD_TARGETS=()
while [[ $# -gt 0 ]]; do
    case "${1}" in
        --chunk-img)
            CHUNK_IMAGE=1
            ;;
        --local-reg)
            LOCAL_REGISTRY=1
            LOCAL_REGISTRY_URL="127.0.0.1:5000"
            ;;
        --build-skp) # Skip building image and proceed to chunking or pushing
            BUILD_SKIP=1
            ;;
        --build-img) # Build specified image(s) (defaults to all builds)
            shift
            BUILD_TARGETS=("$@")
            break
            ;;
        *)
            die "Unknown argument: ${1}"
            ;;
    esac
    shift
done

# Set custom TMP and CACHE directories
declare -x TMPDIR="/tmp/local-build-cache"
mkdir -p "${TMPDIR}"
if [[ -n "${PERSISTENT_CACHE_DIR:-}" ]]; then
    ln -Tvsf "${PERSISTENT_CACHE_DIR}" "${TMPDIR}/buildah-cache-$(id -u)"
fi


# Set local container registry
# This is useful for building images completely without root privileges
# Switch to locally built image with command:
# sudo bootc switch 127.0.0.1:5000/catcat-os:latest
if [[ ${LOCAL_REGISTRY:-} -eq 1 ]]; then
    registries_confd="/etc/containers/registries.conf.d"
    if [[ ! -f "${registries_confd}/local-registry.conf" ]]; then
        echo "[[registry]]
location = \"${LOCAL_REGISTRY_URL}\"
insecure = true" | sudo tee "${registries_confd}/local-registry.conf"
#        echo '[[registry]]
#location = "10.0.0.0:5000"
#insecure = true' | sudo tee "${registries_confd}/localnet-registry.conf"
        sudo chmod -v 644 "${registries_confd}"/*
    fi

    # Run local container registry server
    reg_status="$(podman ps -a --filter status=running --format '{{.Names}}')"
    if [[ ! "${reg_status}" =~ "local-registry" ]]; then
        log "INFO" "Running local container registry in background"
        local_registry_dir="${HOME}/.local/share/containers/local-registry"
        mkdir -p "${local_registry_dir}"
        podman run --name local-registry -d \
                   -p 5000:5000 \
                   -v "${local_registry_dir}":/var/lib/registry:Z \
                   --replace --restart unless-stopped \
                   registry:2
        unset local_registry_dir
    fi
    unset registries_confd reg_status
fi

declare -A BUILDS=(
    [catcat-os]="main|quay.io/fedora-ostree-desktops/silverblue"
    [catcat-os-nv]="nvidia|localhost/catcat-os"
    [catcat-os-hh]="deck|localhost/catcat-os"
)

# If no build target specified, build all images in BUILDS array
if [[ ${#BUILD_TARGETS[@]} -eq 0 ]]; then
    BUILD_TARGETS=("${!BUILDS[@]}")
fi

builder() { "${SCRIPT_DIR}/build.sh" "$@"; }
for VARIANT in "${BUILD_TARGETS[@]}"; do
    if [[ -z "${BUILDS[${VARIANT}]:-}" ]]; then
        die "Variant '${VARIANT}' not found in BUILDS array"
    fi

    IFS='|' read -r ALT_TAG BASE_IMAGE <<< "${BUILDS[${VARIANT}]}"
    if [[ ${BUILD_SKIP:-} -ne 1 ]]; then
        builder build --image-name "${VARIANT}" \
                      --base-image "${BASE_IMAGE}" \
                      --alt-tag    "${ALT_TAG}"
    fi

    if [[ ${CHUNK_IMAGE:-} -eq 1 ]]; then
        builder chunk --image-name "${VARIANT}" \
                      --base-image "${BASE_IMAGE}" \
                      --alt-tag    "${ALT_TAG}"
        VARIANT="${VARIANT}-chunked"
    fi

    if [[ ${LOCAL_REGISTRY:-} -eq 1 ]]; then
        declare -x PUSH_REGISTRY="${LOCAL_REGISTRY_URL}"
        declare -x BUILD_TAGS="${DEFAULT_TAG}"
        builder push  --image-name "${VARIANT}" \
                      --base-image "${BASE_IMAGE}" \
                      --alt-tag    "${ALT_TAG}" \
                      --compression-format "zstd" \
                      --compression-level 19 \
                      --tls-verify=false
    fi
done

dangling_images=($(podman images -f "dangling=true" -q))
if [[ ${#dangling_images[@]} -gt 0 ]]; then
    echo ""
    log "INFO" "Removing dangling images..."
    podman rmi --force ${dangling_images[@]}
    log "INFO" "Removed ${#dangling_images[@]} dangling images"
fi

