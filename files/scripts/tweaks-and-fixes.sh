#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

# to use catcat update
sed -i "s|Exec=.*|Exec=/usr/bin/update all|" /usr/share/applications/system-update.desktop

# topgrade setup
sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' /usr/share/ublue-os/just/10-update.just
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true

# enable disk discard
sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# libvirt setup
sed -i 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' /etc/libvirt/libvirtd.conf
sed -i 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf

# Fix issues caused by ID no longer being fedora
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

# amd gpu opergb support
git clone https://github.com/twifty/amd-gpu-i2c.git /tmp/amd-gpu-i2c
cd /tmp/amd-gpu-i2c
sed -i 's/sudo //g' ./Makefile
make install

