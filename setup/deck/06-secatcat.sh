#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

###########
# Network #
###########
TMP_DIR="${BUILD_CACHE_DIR}/fetched" \
bash -x /usr/bin/localdnsctl -v --switch-backend dnsmasq --setup
