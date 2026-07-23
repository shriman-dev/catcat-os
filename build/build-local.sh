#!/usr/bin/bash
set -euo pipefail
umask 0022
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$(dirname ${SCRIPT_DIR})/files/scripts/script_lib/funcvar.sh"

#set -x

BUILD_TARGETS=()
while [[ $# -gt 0 ]]; do
    case "${1}" in
        --chunk-img)
            CHUNK_IMAGE=1
            ;;
        --local-reg)
            INIT_LOCAL_REGISTRY=1
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
if [[ ${INIT_LOCAL_REGISTRY:-} -eq 1 ]]; then
    registries_confd="/etc/containers/registries.conf.d"
    if [[ ! -f "${registries_confd}/local-registry.conf" ]]; then
        echo '[[registry]]
location = "127.0.0.1:5000"
insecure = true' | sudo tee "${registries_confd}/local-registry.conf"
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

for VARIANT in "${BUILD_TARGETS[@]}"; do
    if [[ -z "${BUILDS[${VARIANT}]:-}" ]]; then
        die "Variant '${VARIANT}' not found in BUILDS array"
    fi

    IFS='|' read -r ALT_TAG BASE_IMAGE <<< "${BUILDS[${VARIANT}]}"
    if [[ ${BUILD_SKIP:-} -ne 1 ]]; then
        bash "${SCRIPT_DIR}"/build.sh --image-name "${VARIANT}" \
                                      --base-image "${BASE_IMAGE}" \
                                      --alt-tag    "${ALT_TAG}"
    fi

    if [[ ${CHUNK_IMAGE:-} -eq 1 ]]; then
        echo ""; symmetric_heading "Creating Chunked Image" "%" "115"
        log "INFO" "Running ostree chunker"
        _cmd_test_timer_start=$(date +%s)
        { brief_trace; } 2>/dev/null
        rpm-ostree compose build-chunked-oci \
                   --bootc --max-layers 250 \
                   --format-version=2 \
                   --from "localhost/${VARIANT}:latest" \
                   --output containers-storage:"localhost/${VARIANT}-chunked:latest"
        VARIANT="${VARIANT}-chunked"
        { brief_trace; } 2>/dev/null
        log "INFO" "Created chunked image in: $(cmd_test_timer)"
    fi
    if [[ ${INIT_LOCAL_REGISTRY:-} -eq 1 ]]; then
        echo ""; symmetric_heading "Pushing To Local Container Registry" "%" "115"
        log "INFO" "Pushing image to local container registry"
        REAL_VARIANT="${VARIANT/-chunked/}"
        _cmd_test_timer_start=$(date +%s)
        { brief_trace; } 2>/dev/null
        podman tag "localhost/${VARIANT}:latest" "localhost:5000/${REAL_VARIANT}:latest"
        podman push --compression-format "zstd" \
                    --compression-level 19 \
                    --tls-verify=false "${VARIANT}:latest" "localhost:5000/${REAL_VARIANT}:latest"
        { brief_trace; } 2>/dev/null
        log "INFO" "Pushed in: $(cmd_test_timer)"
    fi
done

dangling_images=($(podman images -f "dangling=true" -q))
if [[ ${#dangling_images[@]} -gt 0 ]]; then
    log "INFO" "Removing dangling images"
    podman rmi --force ${dangling_images[@]}
    log "INFO" "Removed ${#dangling_images[@]} dangling images"
fi

