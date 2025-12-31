#!/usr/bin/env bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

log "INFO" "Preparing build environment"

log "INFO" "Creating needed directories"
mkdir -vp /etc/dconf/db/distro.d
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d
mkdir -vp /etc/catcat-os
mkdir -vp /var/roothome
mkdir -vp /nix
mkdir -vp /var/tmp
chmod -vR 1777 /var/tmp

# To make /opt immutable, needed for some rpm? packages (browsers, docker-desktop)
rm -v /opt && mkdir -vp /opt

log "INFO" "Adding Update SHA using the Commit SHA value"
echo ${COMMIT_SHA} > /etc/catcat-os/update_sha

log "INFO" "Build environment prepared"
