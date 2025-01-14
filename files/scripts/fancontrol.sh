#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"
###

curl -Lo /tmp/MControlCenterrrr $(curl -s -X GET https://api.github.com/repos/dmitry-s93/MControlCenter/releases/latest | grep -i '"browser_download_url": "[^"]*.tar.gz"' | cut -d '"' -f4)

mkdir -p /tmp/MControlCenter
tar -xf /tmp/MControlCenterrrr -C /tmp/MControlCenter --strip-components=1
cd /tmp/MControlCenter/
/tmp/MControlCenter/install.sh
cd -
