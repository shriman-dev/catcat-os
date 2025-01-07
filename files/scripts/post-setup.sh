
#!/usr/bin/env bash

set -oue pipefail

echo -e "\n$0\n"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# remove stuffs
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
sed -i "s|issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# libvirt setup
sed -i 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' /etc/libvirt/libvirtd.conf
sed -i 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf


# to use catcat-updater
sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' /usr/share/ublue-os/just/10-update.just
sed -i 's|ExecStart=.*|ExecStart=/usr/libexec/catcat-updater|' /usr/lib/systemd/system/ublue-update.service
sed -i 's|OnUnitInactiveSec=.*|OnUnitInactiveSec=2h|' /usr/lib/systemd/system/ublue-update.timer
ln -sfv /usr/libexec/catcat-updater /usr/bin/
cp -v /usr/lib/systemd/system/ublue-update.service /usr/lib/systemd/user/
cp -v /usr/lib/systemd/system/ublue-update.timer /usr/lib/systemd/user/


# set envvars
ENVARS_TO_ADD=(
  "QT_QPA_PLATFORMTHEME=qt5ct"
  "QT_STYLE_OVERRIDE=kvantum"
  "QT_QPA_PLATFORM=xcb,wayland"
  "GNOME_SHELL_SLOWDOWN_FACTOR=0.6"
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


desktop-files() {

  sed -i 's|^Name=.*|Name=CatCat Setup|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop
  sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/catcat-os-logo.svg|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop
  cp -dv /usr/share/ublue-os/firstboot/launcher/autostart.desktop /usr/share/applications/
  sed -i 's|^Exec=.*|Exec=/usr/bin/yafti -f /usr/share/ublue-os/firstboot/yafti.yml|' /usr/share/applications/autostart.desktop

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
desktop-files &

icons() {
  curl -Lo /tmp/papirus $( curl -s -X GET https://api.github.com/repos/PapirusDevelopmentTeam/papirus-icon-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )

  mkdir -p /tmp/papirusicon
  tar -xf /tmp/papirus -C /tmp/papirusicon --strip-components=1
  cp -drf /tmp/papirusicon/Papirus* /usr/share/icons/
}
icons &




themes() {
# defaults
mkdir -p /etc/fastfetch/
cp -dvrf /etc/skel/.config/fastfetch/* /etc/fastfetch/ &
cp -dvrf /etc/skel/.config/Kvantum/* /usr/share/Kvantum/ &
cp -dvrf /etc/skel/.config/qt5ct/* /usr/share/qt5ct/ &
cp -dvrf /etc/skel/.config/qt6ct/* /usr/share/qt6ct/ &

# plymouth
plymouth-set-default-theme catppuccin-mocha &

# gtk
curl -Lo /tmp/lavanda-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Lavanda-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )

mkdir -p /tmp/Lavanda-gtk-theme
tar -xf /tmp/lavanda-gtk-theme -C /tmp/Lavanda-gtk-theme --strip-components=1

/tmp/Lavanda-gtk-theme/install.sh --color light dark &


git clone https://github.com/shriman-dev/Colloid-gtk-theme.git /tmp/colloid-gtk-theme
/tmp/colloid-gtk-theme/install.sh -t all -c dark --tweaks catppuccin rimless

# gdm theme
gdmResource=/usr/share/gnome-shell/gnome-shell-theme.gresource
workDir="/tmp/gnome-shell"
gdmxml=$(basename "$gdmResource").xml

CreateDirs() {
for resource in `gresource list "$gdmResource"`; do
    resource="${resource#\/org\/gnome\/shell\/}"
    if [ ! -d "$workDir"/"${resource%/*}" ]; then
      mkdir -p "$workDir"/"${resource%/*}"
    fi
done
}

ExtractRes() {
for resource in `gresource list "$gdmResource"`; do
    gresource extract "$gdmResource" "$resource" > "$workDir"/"${resource#\/org\/gnome\/shell\/}"
done
}
CreateDirs
ExtractRes

cp -drvf /usr/share/themes/Colloid-Orange-Dark-Catppuccin/gnome-shell/* $workDir/theme/

echo ".login-dialog { background: transparent; }
#lockDialogGroup {
  background-image: url('resource:///org/gnome/shell/theme/background');
  background-position: center;
  background-size: cover;
}" >> $workDir/theme/gnome-shell.css

cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-dark.css
cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-light.css
cp -dv   /usr/share/backgrounds/catcat-os/altos_odyssey_blurred.jpg $workDir/theme/background

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<gresources>
  <gresource prefix=\"/org/gnome/shell/theme\">
$(find ${workDir}/theme/ -type f -not -wholename '*.gresource*' -printf '    <file>%P</file>\n')
  </gresource>
</gresources>" > ${workDir}/theme/${gdmxml}

cat ${workDir}/theme/${gdmxml}

glib-compile-resources --sourcedir=$workDir/theme/ $workDir/theme/"$gdmxml" && mv -v $workDir/theme/$(basename "$gdmResource") $gdmResource &
cp -drf $workDir/* /usr/share/gnome-shell/


cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/

# set defaul icon and theme
sed -i 's/Inherits=.*/Inherits=Catppuccin-Papirus-Orange/' /usr/share/icons/default/index.theme

cp -drf /usr/share/themes/Colloid-Orange-Dark-Catppuccin/{gtk-2.0,gtk-3.0,gtk-4.0} /usr/share/themes/Default/ &
cp -drf /usr/share/themes/Colloid-Orange-Dark-Catppuccin/gtk-4.0 /etc/skel/.config/

/usr/bin/dconf update
}
themes


shell-exts(){
cp -drf /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/


#curl -Lo /tmp/unite.zip $(curl -s -X GET https://api.github.com/repos/hardpixel/unite-shell/releases/latest | grep -i '"browser_download_url": "[^"]*.zip"' | cut -d'"' -f4)

#gnome-extensions install /tmp/unite.zip
echo
}
shell-exts


# last commit sha
mkdir -p /etc/catcat-os/
curl -s -X GET https://api.github.com/repos/shriman-dev/catcat-os/commits | jq -r '.[0].sha' > /etc/catcat-os/update_sha
