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

# to use catcat-updater
sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' /usr/share/ublue-os/just/10-update.just
sed -i 's|ExecStart=.*|ExecStart=/usr/libexec/catcat-updater|' /usr/lib/systemd/system/ublue-update.service
sed -i 's|OnUnitInactiveSec=.*|OnUnitInactiveSec=2h|' /usr/lib/systemd/system/ublue-update.timer
ln -sfv /usr/libexec/catcat-updater /usr/bin/

# remove pip from topgrade config
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true
