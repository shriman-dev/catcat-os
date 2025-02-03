#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

desktopFiles() {
  sed -i 's|^Name=.*|Name=CatCat Setup|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop
  sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/catcat-os-logo.svg|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop
  cp -dv /usr/share/ublue-os/firstboot/launcher/autostart.desktop /usr/share/applications/
  sed -i 's|^Name=.*|Name=Nemo File Manager|' /usr/share/applications/nemo.desktop
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

icons() {
  curl -Lo /tmp/papirus $( curl -s -X GET https://api.github.com/repos/PapirusDevelopmentTeam/papirus-icon-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )

  mkdir -p /tmp/papirusicon
  tar -xf /tmp/papirus -C /tmp/papirusicon --strip-components=1
  cp -drf /tmp/papirusicon/Papirus* /usr/share/icons/
}

gtkThemes() {
  # Lavanda-gtk-theme
  curl -Lo /tmp/lavanda-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Lavanda-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )
  mkdir -p /tmp/Lavanda-gtk-theme
  tar -xf /tmp/lavanda-gtk-theme -C /tmp/Lavanda-gtk-theme --strip-components=1
  /tmp/Lavanda-gtk-theme/install.sh --color light dark

  # Catppuccin-Gtk-Theme
  git clone https://github.com/shriman-dev/Catppuccin-Gtk-Theme.git /tmp/Catppuccin-Gtk-Theme
  chmod +x /tmp/Catppuccin-Gtk-Theme/install.sh
  /tmp/Catppuccin-Gtk-Theme/install.sh --name 'Catppuccin' --theme all --color dark --tweaks catppuccin rimless
}

gdmTheme() {
  gdmResource=/usr/share/gnome-shell/gnome-shell-theme.gresource
  workDir="/tmp/gnome-shell"
  gdmxml=$(basename "$gdmResource").xml

  # Create Dirs
  for resource in `gresource list "$gdmResource"`; do
      resource="${resource#\/org\/gnome\/shell\/}"
      if [ ! -d "$workDir"/"${resource%/*}" ]; then
        mkdir -p "$workDir"/"${resource%/*}"
      fi
  done

  # Extract Resources
  for resource in `gresource list "$gdmResource"`; do
      gresource extract "$gdmResource" "$resource" > "$workDir"/"${resource#\/org\/gnome\/shell\/}"
  done

  # Get custom-default shell theme
  cp -drvf /usr/share/themes/Catppuccin-Orange-Dark/gnome-shell/* $workDir/theme/

 # Set background wallpaper in css
  echo ".login-dialog { background: transparent; }
#lockDialogGroup {
  background-image: url('resource:///org/gnome/shell/theme/background');
  background-position: center;
  background-size: cover;
}" >> $workDir/theme/gnome-shell.css
  cp -dv   /usr/share/backgrounds/catcat-os/altos_odyssey_blurred.jpg $workDir/theme/background

  # Use same css for  light or dark mode
  cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-dark.css
  cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-light.css

  # Declare resources in xml file
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<gresources>
  <gresource prefix=\"/org/gnome/shell/theme\">
$(find ${workDir}/theme/ -type f -not -wholename '*.gresource*' -printf '    <file>%P</file>\n')
  </gresource>
</gresources>" > ${workDir}/theme/${gdmxml}
  cat ${workDir}/theme/${gdmxml}

  # Compile all resources to use for gdm theme
  glib-compile-resources --sourcedir=$workDir/theme/ $workDir/theme/"$gdmxml" &&
  mv -v $workDir/theme/$(basename "$gdmResource") $gdmResource

  # Default settings for gdm
  cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/
}

defaultConfigs() {
  mkdir -p /etc/fastfetch/
  cp -dvrf /etc/skel/.config/fastfetch/* /etc/fastfetch/ 
  cp -dvrf /etc/skel/.config/Kvantum/* /usr/share/Kvantum/
  cp -dvrf /etc/skel/.config/qt5ct/* /usr/share/qt5ct/
  cp -dvrf /etc/skel/.config/qt6ct/* /usr/share/qt6ct/

  # set defaul icon and theme
  sed -i 's/Inherits=.*/Inherits=Catppuccin-Papirus-Orange/' /usr/share/icons/default/index.theme

  cp -drf /usr/share/themes/Catppuccin-Orange-Dark/{gtk-2.0,gtk-3.0,gtk-4.0} /usr/share/themes/Default/
  cp -drf /usr/share/themes/Catppuccin-Orange-Dark/gtk-4.0 /etc/skel/.config/

  /usr/bin/dconf update

  tree /etc/dconf/
  mkdir -p /etc/skel/.config/dconf
  cp -dvf /etc/dconf/db/distro /etc/skel/.config/dconf/user

  # Set plymouth theme
  plymouth-set-default-theme catppuccin-mocha
}

shellExts() {
  cp -drf /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/
  #curl -Lo /tmp/unite.zip $(curl -s -X GET https://api.github.com/repos/hardpixel/unite-shell/releases/latest | grep -i '"browser_download_url": "[^"]*.zip"' | cut -d'"' -f4)
  #gnome-extensions install /tmp/unite.zip
  echo
}

desktopFiles &
icons &
gtkThemes &
gdmTheme &
shellExts &
defaultConfigs &