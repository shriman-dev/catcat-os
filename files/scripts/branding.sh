#!/usr/bin/env bash
set -oue pipefail
echo -e "\n$0\n"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# remove stuffs
rm -rvf /etc/skel/.config/autostart /etc/skel/.mozilla /etc/skel/.config/user-tmpfiles.d

# os naming
sed -i 's/^ID=.*/ID=catcat/' /usr/lib/*release
sed -i 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="catcat"/' /usr/lib/*release
sed -i 's/^NAME=.*/NAME="CatCat OS"/' /usr/lib/*release
sed -i 's/Bazzite/CatCat OS/' /usr/lib/*release
sed -i '/^VARIANT_ID=/s/bazzite.\+/catcat/' /usr/lib/*release

cp -dvf /usr/share/pixmaps/fedora-logo-sprite.png /usr/share/plymouth/themes/spinner/watermark.png
