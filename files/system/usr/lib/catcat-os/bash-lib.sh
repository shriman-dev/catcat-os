#!/usr/bin/env bash
SRC_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bash-lib"
QUIET=${QUIET:-false}
VERBOSE=${VERBOSE:-2}

source "${SRC_DIR}/color-lib.sh"
source "${SRC_DIR}/logging.sh"
source "${SRC_DIR}/interface.sh"
source "${SRC_DIR}/sys-utils.sh"
source "${SRC_DIR}/file-utils.sh"
source "${SRC_DIR}/path-utils.sh"
source "${SRC_DIR}/file-ops.sh"
source "${SRC_DIR}/text-utils.sh"
source "${SRC_DIR}/net-utils.sh"
source "${SRC_DIR}/net-get.sh"

unset SRC_DIR
