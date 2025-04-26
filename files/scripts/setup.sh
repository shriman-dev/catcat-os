#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

echo ${COMMIT_SHA}
echo ${IMAGE_NAME} ${MAJOR_VERSION}
echo ${COMMIT_SHA}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$SCRIPT_DIR/cleanup.sh

# copy system files
FILESDIR="$(dirname $SCRIPT_DIR)"
mkdir -p /var/lib/alternatives
mkdir -p /usr/etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/system/* /
cp -drvf ${FILESDIR}/dconf/*  /etc/dconf/db/distro.d/
cp -drvf ${FILESDIR}/dconf/*  /usr/etc/dconf/db/distro.d/
cp -drf  ${FILESDIR}/skel     /etc/

# Setup justfiles
IMPORT_FILE="/usr/share/ublue-os/justfile"
for JUSTFILE in ${FILESDIR}/justfiles/*.just; do
  cp -dvf "${JUSTFILE}" /usr/share/ublue-os/just/
  IMPORT_LINE="import \"/usr/share/ublue-os/just/$(basename ${JUSTFILE})\""
  # Add import line if it does not exists already
  grep -w "${IMPORT_LINE}" "${IMPORT_FILE}" || {
    sed -i "/# Imports/a\\${IMPORT_LINE}" "${IMPORT_FILE}"
    cat "${IMPORT_FILE}"
    echo "Added: '${IMPORT_LINE}' to ${IMPORT_FILE}"
  }
done

# last commit sha
mkdir -p /etc/catcat-os/
echo ${COMMIT_SHA} > /etc/catcat-os/update_sha

[[ $IMAGE_NAME == 'catcat-os' ]] && $SCRIPT_DIR/fancontrol.sh

$SCRIPT_DIR/rpm-ostree.sh
$SCRIPT_DIR/extra-pkgs.sh
$SCRIPT_DIR/branding.sh
$SCRIPT_DIR/tweaks-and-fixes.sh
$SCRIPT_DIR/config-and-theming.sh
$SCRIPT_DIR/nerd-fonts.sh
$SCRIPT_DIR/security.sh
$SCRIPT_DIR/systemd.sh
$SCRIPT_DIR/initramfs.sh
$SCRIPT_DIR/signing.sh






