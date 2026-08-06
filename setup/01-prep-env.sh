#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Preparing build environment"
# To use cached sbmok.der
mkdir -vp "/usr/share/${PROJECT_NAME}/certs" "/etc/pki/akmods/certs"
SBMOK_DER="${BUILD_CACHE_DIR}/sbmok.der"
[[ ! -f "${SBMOK_DER}" ]] && SBMOK_DER="${BUILD_ROOT_DIR}/sbmok.der"
cp -vf "${SBMOK_DER}" "/usr/share/${PROJECT_NAME}/certs/${PROJECT_NAME}-mok.der"
cp -vf "${SBMOK_DER}" "/etc/pki/akmods/certs/${PROJECT_NAME}-mok.der"
env

log "INFO" "Creating needed directories"
mkdir -vp "${BUILD_CACHE_DIR}/system"/{etc,usr} \
          "${BUILD_CACHE_DIR}/conf_repos" \
          "${BUILD_CACHE_DIR}/fetched" \
          "${BUILD_CACHE_DIR}/rpm"

mkdir -vp "/etc/${PROJECT_NAME}" \
          "/etc/skel/.local/share/${PROJECT_NAME}" \
          "/usr/lib/${PROJECT_NAME}" \
          "/usr/share/${PROJECT_NAME}" \
          "/usr/share/backgrounds/${PROJECT_NAME}"

mkdir -vp /etc/dconf/db/distro.d \
          /var/tmp \
          /var/roothome \
          /var/lib/alternatives \
          /nix

chmod -vR 1777 /var/tmp

log "INFO" "Caching repositories with configurations"
ensure_repo "https://github.com/CachyOS/CachyOS-Settings.git" \
            "${BUILD_CACHE_DIR}/conf_repos/cachyos_settings"

ensure_repo "https://github.com/ublue-os/packages.git" \
            "${BUILD_CACHE_DIR}/conf_repos/ublue_packages"

# To make /opt immutable, needed for some rpm? packages (browsers, docker-desktop)
if [[ -L /opt ]]; then
    rm -v /opt
    mkdir -vp /opt
fi

log "INFO" "Adding build info"
mkdir -vp "/etc/${PROJECT_NAME}"
cat <<EOF > "/etc/${PROJECT_NAME}/build_info"
BUILD_EPOCH=$(date +%s)
COMMIT_SHA='${COMMIT_SHA}'
DATETIMESTAMP='${DATESTAMP}.${TIMESTAMP}'
EOF

log "INFO" "Build environment prepared"
