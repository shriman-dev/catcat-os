#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# copy system files
FILESDIR="$(dirname $SCRIPT_DIR)"
cp -drf  ${FILESDIR}/system/* /
cp -drvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
cp -drvf ${FILESDIR}/dconf/*  /usr/etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/skel     /etc/

$SCRIPT_DIR/cleanup.sh
$SCRIPT_DIR/pre-setup.sh
$SCRIPT_DIR/rpm-ostree.sh
$SCRIPT_DIR/flatpak.sh
$SCRIPT_DIR/systemd.sh
$SCRIPT_DIR/nerd-fonts.sh
$SCRIPT_DIR/post-setup.sh
$SCRIPT_DIR/initramfs.sh







