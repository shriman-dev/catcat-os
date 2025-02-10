#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

# to use catcat-updater
sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' /usr/share/ublue-os/just/10-update.just
sed -i 's|ExecStart=.*|ExecStart=/usr/libexec/catcat-updater|' /usr/lib/systemd/system/ublue-update.service
sed -i 's|OnUnitInactiveSec=.*|OnUnitInactiveSec=2h|' /usr/lib/systemd/system/ublue-update.timer
ln -sfv /usr/libexec/catcat-updater /usr/bin/

# remove pip from topgrade config
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true


# Fix issues caused by ID no longer being fedora
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

# enable disk discard
sed -i "s|issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# libvirt setup
sed -i 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' /etc/libvirt/libvirtd.conf
sed -i 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

