#!/usr/bin/env bash

set -oue pipefail

sed -i '/^PRETTY_NAME/s/Bazzite/CatCat/' /usr/lib/os-release
sed -i "s|.*issue_discards =.*|issue_discards = 1|"  /etc/lvm/lvm.conf
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed  -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf
 

systemctl enable fstrim.timer nix.mount \
                 everyFewMins.service everyFewMins.timer catcat-system-setup.service
