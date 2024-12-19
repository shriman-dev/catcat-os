#!/usr/bin/env bash

set -oue pipefail
pwd

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# remove stuffs
find /etc/skel -type f -name ".gitkeep" -delete
rm -rvf /etc/skel/.config/autostart
rm -rvf /etc/skel/.mozilla
rm -rvf /etc/skel/.config/user-tmpfiles.d

# os naming
sed -i 's/^ID=.*/ID=catcat/' /usr/lib/*release
sed -i 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="catcat"/' /usr/lib/*release
sed -i 's/^NAME=.*/NAME="CatCat OS"/' /usr/lib/*release
sed -i 's/Bazzite/CatCat OS/' /usr/lib/*release
sed -i '/^VARIANT_ID=/s/bazzite.\+/catcat/' /usr/lib/*release

# enable disk discard
sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# set envars
ENVARS_TO_ADD=(
  "QT_QPA_PLATFORMTHEME=qt5ct"
  "QT_QPA_PLATFORM=wayland,xcb"
  "GNOME_SHELL_SLOWDOWN_FACTOR=0.7"
  "MICRO_TRUECOLOR=1"
)

for v in "${ENVARS_TO_ADD[@]}"; do
  [[ ! $(grep "^$v" /etc/environment) ]] && echo "$v" >> /etc/environment
done

# remove pip from topgrade config
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf


systemctl enable fstrim.timer nix.mount catcat-system-setup.service \
                 auto-power-profile.service


desktop-files(){
cp -dvf /usr/share/applications/syncthing-start.desktop /etc/xdg/autostart/


sed -i 's/^Icon=.*/Icon=user-home/' /usr/share/applications/org.gnome.Nautilus.desktop
sed -i 's/^Exec=.*/Exec=nautilus --new-window Me\//;/DBusActivatable/d' /usr/share/applications/org.gnome.Nautilus.desktop
sed -i 's/^Icon=.*/Icon=fish/' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's/^Icon=.*/Icon=mintsources-maintenance/' /usr/share/applications/org.gnome.Settings.desktop
sed -i 's/^Icon=.*/Icon=np2/' /usr/share/applications/oneko.desktop
sed -i 's|^Icon=.*|Icon=/usr/share/icons/yazi.png|' /usr/share/applications/yazi.desktop

sed -i 's/^NoDisplay=.*/NoDisplay=false/' /usr/share/applications/nvtop.desktop || true
sed -i 's/^NoDisplay=.*/NoDisplay=false/' /usr/share/applications/btop.desktop || true
sed -i 's/^NoDisplay=.*/NoDisplay=false/' /usr/share/applications/yad-icon-browser.desktop || true
}
desktop-files



themes(){
plymouth-set-default-theme catppuccin-mocha

mkdir -p /etc/fastfetch/
cp -dvrfu /usr/etc/skel/.config/fastfetch/* /etc/fastfetch/
cp -dvrfu /usr/etc/skel/.config/Kvantum/* /usr/share/Kvantum/
cp -dvrfu /usr/etc/skel/.config/qt5ct/* /usr/share/qt5ct/

curl -Lo /tmp/colloid-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Colloid-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d'"' -f4 )

mkdir -p /tmp/Colloid-gtk-theme
tar -xf /tmp/colloid-gtk-theme -C /tmp/Colloid-gtk-theme --strip-components=1

cp -dvf ${SCRIPT_DIR}/setup-files/_color-palette-catppuccin.scss /tmp/Colloid-gtk-theme/src/sass

sed  -i 's/\$modal-radius: .*;/\$modal-radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/_variables.scss
sed  -i 's/\$corner-radius: .*;/\$corner-radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/_variables.scss

sed  -i 's/\$base_radius: .*;/\$base_radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss
sed  -i 's/\$icon_radius: .*;/\$icon_radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss
sed  -i 's/\$window_radius: .*;/\$window_radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/gnome-shell/_variables.scss

sed  -i 's/\$button_radius: .*;/\$button_radius: 18px;/g' /tmp/Colloid-gtk-theme/src/sass/libadwaita/_variables.scss

/tmp/Colloid-gtk-theme/install.sh -t all -c dark --tweaks catppuccin rimless

mkdir -p /usr/share/gnome-shell/theme/

cp -rf /usr/share/themes/Colloid-Orange-Dark-Catppuccin/gnome-shell /usr/share/gnome-shell/theme/Colloid-Orange-Dark-Catppuccin
ln -svf /usr/share/gnome-shell/theme/Colloid-Orange-Dark-Catppuccin/gnome-shell.css /usr/share/gnome-shell/theme/gnome-shell.css


curl -Lo /tmp/lavanda-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Lavanda-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )

mkdir -p /tmp/Lavanda-gtk-theme
tar -xf /tmp/lavanda-gtk-theme -C /tmp/Lavanda-gtk-theme --strip-components=1

/tmp/Lavanda-gtk-theme/install.sh

/usr/bin/dconf update
}
themes


shell-exts(){
cp -drfu /usr/etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/

#sed -i '/"46"/s/"46"/&,/; /"46"/a\    "47"' /usr/share/gnome-shell/extensions/quick-settings-tweaks@qwreey/metadata.json

#curl -Lo /tmp/unite.zip $(curl -s -X GET https://api.github.com/repos/hardpixel/unite-shell/releases/latest | grep -i '"browser_download_url": "[^"]*.zip"' | cut -d'"' -f4)

#gnome-extensions install /tmp/unite.zip
echo
}
shell-exts
