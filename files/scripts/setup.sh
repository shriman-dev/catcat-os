#!/usr/bin/env bash

set -oue pipefail
pwd

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sed -i '/^ID/s/bazzite/catcat/' /usr/lib/*release
sed -i '/^DEFAULT_HOSTNAME/s/bazzite/catcat/' /usr/lib/*release
sed -i 's/Bazzite/CatCat/' /etc/*release
sed -i "s|.*issue_discards =.*|issue_discards = 1|"  /etc/lvm/lvm.conf
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed  -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf
 

systemctl enable fstrim.timer nix.mount \
                 everyFewMins.service everyFewMins.timer catcat-system-setup.service


gtk-themes(){

curl -Lo /tmp/colloid-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Colloid-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d'"' -f4 )

mkdir -p /tmp/Colloid-gtk-theme
tar -xf /tmp/colloid-gtk-theme -C /tmp/Colloid-gtk-theme --strip-components=1

cp -vf ${SCRIPT_DIR}/_color-palette-catppuccin.scss /tmp/Colloid-gtk-theme/src/sass
sed  -i 's/\$window-radius: .*;/\$window-radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/_variables.scss
sed  -i 's/\$modal-radius: .*;/\$modal-radius: 12px;/g' /tmp/Colloid-gtk-theme/src/sass/_variables.scss
sed  -i 's/\$corner-radius: .*;/\$corner-radius: 12px;/g' /tmp/Colloid-gtk-theme/src/sass/_variables.scss

sed  -i 's/\$base_radius: .*;/\$base_radius: 12px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss
sed  -i 's/\$icon_radius: .*;/\$icon_radius: 20px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss
sed  -i 's/\$window_radius: .*;/\$window_radius: 16px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss


/tmp/Colloid-gtk-theme/install.sh -t all -c dark --tweaks catppuccin rimless

}
gtk-themes


shell-exts(){

curl -Lo /tmp/unite.zip $(curl -s -X GET https://api.github.com/repos/hardpixel/unite-shell/releases/latest | grep -i '"browser_download_url": "[^"]*.zip"' | cut -d'"' -f4)

gnome-extensions install /tmp/unite.zip


}
shell-exts
