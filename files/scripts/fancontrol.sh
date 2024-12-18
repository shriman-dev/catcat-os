#!/bin/bash
set -oue pipefail
pwd
###
curl -Lo /tmp/MControlCenterrrr https://github.com/dmitry-s93/MControlCenter/releases/latest/download/MControlCenter-0.4.1-bin.tar.gz

mkdir -p /tmp/MControlCenter
tar -xf /tmp/MControlCenterrrr -C /tmp/MControlCenter --strip-components=1
cd /tmp/MControlCenter/
/tmp/MControlCenter/install.sh
cd -
