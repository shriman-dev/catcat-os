#!/usr/bin/env bash
source ${SETUP_DIR}/funcvar.sh
set -ouex pipefail

log "INFO" "Creating needed directories"
mkdir -vp /etc/dconf/db/distro.d
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d
mkdir -vp /etc/catcat-os
mkdir -vp /var/roothome
mkdir -vp /nix

rm -v /opt && mkdir -vp /opt # To make /opt immutable, needed for some pkgs (chrome, docker-desktop)

log "INFO" "Adding Update SHA with the Commit SHA value"
echo ${COMMIT_SHA} > /etc/catcat-os/update_sha
