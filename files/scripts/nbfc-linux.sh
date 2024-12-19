#!/bin/bash
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/nbfc-linux/nbfc-linux/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)
