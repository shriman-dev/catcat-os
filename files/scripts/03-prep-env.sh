#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Preparing build environment"

log "INFO" "Creating needed directories"
mkdir -vp "/etc/${PROJECT_NAME}" \
          "/etc/skel/.local/share/${PROJECT_NAME}" \
          "/usr/lib/${PROJECT_NAME}" \
          "/usr/share/${PROJECT_NAME}" \
          "/usr/share/backgrounds/${PROJECT_NAME}"

mkdir -vp /etc/environment.d \
          /etc/dconf/db/distro.d \
          /var/tmp \
          /var/roothome \
          /var/lib/alternatives \
          /nix

chmod -vR 1777 /var/tmp

# To make /opt immutable, needed for some rpm? packages (browsers, docker-desktop)
if [[ -L /opt ]]; then
    rm -v /opt
    mkdir -vp /opt
fi

log "INFO" "Adding build info"

cat <<EOF >"/etc/${PROJECT_NAME}/build_info"
BUILD_EPOCH=$(date +%s)
COMMIT_SHA='${COMMIT_SHA}'
DATETIMESTAMP='${DATESTAMP}.${TIMESTAMP}'
EOF

log "INFO" "Build environment prepared"
