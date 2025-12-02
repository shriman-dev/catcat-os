#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

log "INFO" "Running post build image cleanup"

dnf5 clean all
rm -rf /tmp/* || true
find /var/* -maxdepth 0 -type d -not -name "cache" -exec rm -rf {} \;
find /var/cache/* -maxdepth 0 -type d -not -name "libdnf5" -not -name "rpm-ostree" -exec rm -rf {} \;
mkdir -p /var/tmp
chmod -R 1777 /var/tmp
