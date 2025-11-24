#!/usr/bin/env bash
set -oue pipefail
source ${SETUP_DIR}/funcvar.sh

log "INFO" "Creating needed directories"
mkdir -vp /usr/etc/dconf/db/distro.d
mkdir -vp /etc/dconf/db/distro.d
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/catcat-os
mkdir -vp /var/roothome
mkdir -vp /nix

log "INFO" "Adding Update SHA with the Commit SHA value"
echo ${COMMIT_SHA} > /etc/catcat-os/update_sha
