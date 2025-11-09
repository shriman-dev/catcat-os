#!/bin/bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh
echo -e "\n$0\n"

desktopFiles() {
  # to use catcat update
  sed -i "s|^Exec=.*|Exec=/usr/bin/sudo /usr/bin/update all|" /usr/share/applications/system-update.desktop

  sed -i 's|^Name=.*|Name=CatCat Setup|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop || true
  sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/catcat-os-logo.svg|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop || true
  cp -dv /usr/share/ublue-os/firstboot/launcher/autostart.desktop /usr/share/applications/ || true
  sed -i 's|^Exec=.*|Exec=/usr/bin/yafti -f /usr/share/ublue-os/firstboot/yafti.yml|' /usr/share/applications/autostart.desktop || true
  sed -i 's|^Name=.*|Name=Nemo File Manager|' /usr/share/applications/nemo.desktop

  sed -i 's/^Icon=.*/Icon=user-home/' /usr/share/applications/org.gnome.Nautilus.desktop
  sed -i 's/^Exec=.*/Exec=nautilus --new-window Me\//;/DBusActivatable/d' /usr/share/applications/org.gnome.Nautilus.desktop
  sed -i 's/^Icon=.*/Icon=fish/' /usr/share/applications/org.gnome.Ptyxis.desktop
  sed -i 's/^Icon=.*/Icon=mintsources-maintenance/' /usr/share/applications/org.gnome.Settings.desktop
  sed -i 's/^Icon=.*/Icon=np2/' /usr/share/applications/oneko.desktop
  sed -i 's|^Icon=.*|Icon=/usr/share/icons/yazi.png|' /usr/share/applications/yazi.desktop

  sed -i 's|^Icon=.*|Icon=appgrid|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop || true
  sed -i 's|^Name.*=.*|Name=Software Store|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop || true

  sed -i 's|^Exec=.*|Exec=/usr/bin/catcat-waydroid-launcher|' /usr/share/applications/Waydroid.desktop

  sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/nvtop.desktop || true
  sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/yad-icon-browser.desktop || true
  sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/amdgpu_top.desktop || true
  sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/amdgpu_top-tui.desktop || true

}

icons() {
  curl -Lo /tmp/papirus $(curl -s -X GET https://api.github.com/repos/PapirusDevelopmentTeam/papirus-icon-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4)

  mkdir -vp /tmp/papirusicon
  tar -xf /tmp/papirus -C /tmp/papirusicon --strip-components=1
  cp -drf /tmp/papirusicon/Papirus* /usr/share/icons/
}

gtkThemes() {
  # Lavanda-gtk-theme
  curl -Lo /tmp/lavanda-gtk-theme $( curl -s -X GET https://api.github.com/repos/vinceliuice/Lavanda-gtk-theme/releases/latest | grep -i '"tarball_url"' | cut -d '"' -f4 )
  mkdir -vp /tmp/Lavanda-gtk-theme
  tar -xf /tmp/lavanda-gtk-theme -C /tmp/Lavanda-gtk-theme --strip-components=1
  /tmp/Lavanda-gtk-theme/install.sh --color light dark

  # Catppuccin-Gtk-Theme
  git clone https://github.com/shriman-dev/Catppuccin-Gtk-Theme.git /tmp/Catppuccin-Gtk-Theme
  chmod +x /tmp/Catppuccin-Gtk-Theme/install.sh
  /tmp/Catppuccin-Gtk-Theme/install.sh --name 'Catppuccin' --theme all --color dark --tweaks catppuccin rimless
}

gdmTheme() {
  gdmResource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
  workDir="/tmp/gnome-shell"
  gdmxml="$(basename "$gdmResource").xml"
  themePath="/usr/share/themes/Catppuccin-Orange-Dark/gnome-shell"

  # Create directories and extract resources from gresource file
  for resource in $(gresource list "$gdmResource"); do
    resourcePath="${resource#\/org\/gnome\/shell\/}"
    mkdir -p "$workDir"/"${resourcePath%/*}"
    gresource extract "$gdmResource" "$resource" > "$workDir/$resourcePath"
  done

  # Copy custom theme files to working directory
  cp -drvf "$themePath"/* $workDir/theme/

  # Set background wallpaper and modify CSS for login and lock screen
  echo ".login-dialog { background: transparent; }
#lockDialogGroup {
  background-image: url('resource:///org/gnome/shell/theme/background');
  background-position: center;
  background-size: cover;
}" >> $workDir/theme/gnome-shell.css
  cp -dv   /usr/share/backgrounds/catcat-os/altos_odyssey_blurred.jpg $workDir/theme/background

  # Ensure the same CSS is used for both light and dark modes
  cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-dark.css
  cp -drvf $workDir/theme/gnome-shell.css $workDir/theme/gnome-shell-light.css

  # Generate gresource XML file for compiling resources
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<gresources>
  <gresource prefix=\"/org/gnome/shell/theme\">
$(find ${workDir}/theme/ -type f -not -wholename '*.gresource*' -printf '    <file>%P</file>\n')
  </gresource>
</gresources>" > ${workDir}/theme/${gdmxml}
  cat ${workDir}/theme/${gdmxml}

  # Compile all resources and apply them to the gdm theme
  glib-compile-resources --sourcedir=$workDir/theme/ $workDir/theme/"$gdmxml"
  mv -v $workDir/theme/$(basename "$gdmResource") $gdmResource

  # Default settings for gdm
  cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/
}

defaultConfigs() {
  # install extensions for vscodium
  mkdir -p /etc/skel/.vscode-oss/extensions
  mkdir -p /tmp/vscodiumdata
  EXTLIST=(
"jeronimoekerdt.color-picker-universal"
"catppuccin.catppuccin-vsc"
"catppuccin.catppuccin-vsc-icons"
"ms-python.python"
"ericsia.pythonsnippets3pro"
"ms-toolsai.jupyter"
"redhat.vscode-yaml"
"huntertran.auto-markdown-toc"
"zaaack.markdown-editor"
)
  for ext in "${EXTLIST[@]}"; do
    codium --no-sandbox --user-data-dir /tmp/vscodiumdata --extensions-dir /etc/skel/.vscode-oss/extensions --install-extension ${ext}
  done


  # set defaul icon and theme
  sed -i 's/Inherits=.*/Inherits=Catppuccin-Papirus-Orange/' /usr/share/icons/default/index.theme

  cp -drf /usr/share/themes/Catppuccin-Orange-Dark/{gtk-2.0,gtk-3.0,gtk-4.0} /usr/share/themes/Default/
  cp -drf /usr/share/themes/Catppuccin-Orange-Dark/gtk-4.0 /etc/skel/.config/

  /usr/bin/dconf update

  tree /etc/dconf/
  mkdir -p /etc/skel/.config/dconf
#  cp -dvf /etc/dconf/db/distro /etc/skel/.config/dconf/user

  # Set plymouth theme
  plymouth-set-default-theme catppuccin-mocha
}

shellExts() {
  cp -drf /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/
  #curl -Lo /tmp/unite.zip $(curl -s -X GET https://api.github.com/repos/hardpixel/unite-shell/releases/latest | grep -i '"browser_download_url": "[^"]*.zip"' | cut -d'"' -f4)
  #gnome-extensions install /tmp/unite.zip
  echo
}

desktopFiles
icons
gtkThemes
gdmTheme
shellExts
defaultConfigs
