#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

desktop_files() {
    log "INFO" "Configuring desktop files"

    local desktopfile_dir="/usr/share/applications"
    # To use catcat update
    sed -i "s|^Exec=.*|Exec=/usr/bin/sudo /usr/bin/update all|" "${desktopfile_dir}"/system-update.desktop || true

    sed -i 's|^Name=.*|Name=CatCat Setup|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop || true
    sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/catcat-os-logo.svg|' /usr/share/ublue-os/firstboot/launcher/autostart.desktop || true
    #cp -dv /usr/share/ublue-os/firstboot/launcher/autostart.desktop "${desktopfile_dir}"/ || true
    sed -i 's|^Exec=.*|Exec=/usr/bin/yafti -f /usr/share/ublue-os/firstboot/yafti.yml|' "${desktopfile_dir}"/autostart.desktop || true

    sed -i 's|^Name=.*|Name=Nemo File Manager|' "${desktopfile_dir}"/nemo.desktop || true
    sed -i 's/^Icon=.*/Icon=user-home/' "${desktopfile_dir}"/org.gnome.Nautilus.desktop
    sed -i 's/^Exec=.*/Exec=nautilus --new-window Me\//;/DBusActivatable/d' "${desktopfile_dir}"/org.gnome.Nautilus.desktop
    sed -i 's/^Icon=.*/Icon=fish/' "${desktopfile_dir}"/org.gnome.Ptyxis.desktop
    sed -i 's/^Icon=.*/Icon=mintsources-maintenance/' "${desktopfile_dir}"/org.gnome.Settings.desktop
    sed -i 's/^Icon=.*/Icon=np2/' "${desktopfile_dir}"/oneko.desktop
    sed -i 's|^Icon=.*|Icon=/usr/share/icons/yazi.png|' "${desktopfile_dir}"/yazi.desktop || true

    sed -i 's|^Name.*=.*|Name=Software Store|' "${desktopfile_dir}"/io.github.kolunmi.Bazaar.desktop || true

    sed -i 's|^Exec=.*|Exec=/usr/bin/catcat-waydroid-launcher|' "${desktopfile_dir}"/Waydroid.desktop

    # Hide desktop entries
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/nvtop.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/fish.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/yad-icon-browser.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/amdgpu_top.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/amdgpu_top-tui.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/bottom.desktop || true

    log "INFO" "Done configuring desktop files"
}

set_plymouth_theme() {
    log "INFO" "Applying plymouth theme"

    local plymouth_theme="catppuccin-mocha"
    plymouth-set-default-theme "${plymouth_theme}"

    log "INFO" "Plymouth theme applied"
}

install_fonts() {
    log "INFO" "Defining Fonts"
    local -A EXTRA_FONTS=(
        # Nerd Fonts
        # When Nerd Font name is correct, URL is not required
        ['AdwaitaMono']=
        ['FiraCode']=
        ['Hack']=
        ['NerdFontsSymbolsOnly']=

        # From URL
        ['SFMonoNF']="\
https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized.git"

        ['FontAwesome']="\
$(latest_ghpkg_url 'FortAwesome/Font-Awesome' 'desktop\.zip')"

        ['NotoColorEmoji']="\
https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
    )

    log "INFO" "Installing Extra Font(s)"
    local FONTS_DIR="/usr/share/fonts" TMP_DIR="/tmp/extra_fonts" font_name font_url
    for font_name in "${!EXTRA_FONTS[@]}"; do
        font_url="${EXTRA_FONTS[${font_name}]}"
        font_name=${font_name// /} # remove spaces
        get_fonts "${font_name}" "${font_url}"
    done
    rm -rf "${TMP_DIR}"
    log "INFO" "Extra Font(s) installed"

    log "INFO" "Building font cache"
    # Permit global fonts to be used by all users
    # Directories: 755, Files: 644
    find "${FONTS_DIR}" -type d -exec chmod 755 {} + || true
    find "${FONTS_DIR}" -type f -exec chmod 644 {} + || true

    fc-cache --system-only --really-force "${FONTS_DIR}"
    log "INFO" "Done"
}

install_icon_themes() {
    log "INFO" "Installing icons"

    log "INFO" "Papirus icons"
    local JQ_FILTER='.tarball_url'
    local latest_icons_url="$(latest_ghpkg_url 'PapirusDevelopmentTeam/papirus-icon-theme')"
    local icons_archive="/tmp/icons/$(basename ${latest_icons_url}).tar"

    mkdir -vp "$(dirname ${icons_archive})"
    curl_get "${icons_archive}" "${latest_icons_url}"
    unarchive "${icons_archive}" "${icons_archive}.extract" >/dev/null
    cp -drf "${icons_archive}.extract"/Papirus*/Papirus* /usr/share/icons/

    rm -rf /tmp/icons
    log "INFO" "Icons installed"
}

install_gtk_themes() {
    log "INFO" "Installing GTK theme(s)"
    # Lavanda-gtk-theme
    log "INFO" "Lavanda-gtk-theme"
    local JQ_FILTER='.tarball_url'
    local latest_lavanda_url="$(latest_ghpkg_url 'vinceliuice/Lavanda-gtk-theme')"
    local lavanda_tar="/tmp/themes/$(basename ${latest_lavanda_url}).tar"

    mkdir -vp "$(dirname ${lavanda_tar})"
    curl_get "${lavanda_tar}" "${latest_lavanda_url}"
    unarchive "${lavanda_tar}" "${lavanda_tar}.extract" >/dev/null

    chmod -v +x "${lavanda_tar}.extract"/*/install.sh
    "${lavanda_tar}.extract"/*/install.sh --color light dark

    rm -rf "${lavanda_tar}"*

    # Catppuccin-Gtk-Theme
    log "INFO" "Catppuccin-Gtk-Theme"
    local catppuccin_theme_repo="https://github.com/shriman-dev/Catppuccin-Gtk-Theme.git"
    local catppuccin_theme_tmp="/tmp/themes/Catppuccin-Gtk-Theme"
    git clone --depth 1 "${catppuccin_theme_repo}" "${catppuccin_theme_tmp}"
    chmod -v +x "${catppuccin_theme_tmp}"/install.sh
    "${catppuccin_theme_tmp}"/install.sh --name 'Catppuccin' --theme all \
                                            --color dark --tweaks catppuccin rimless
    rm -rf /tmp/themes
    log "INFO" "GTK theme(s) installed"
}

build_gdm_theme() {
    log "INFO" "Building GDM theme"

    local gdm_resource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
    local gmd_theme_tmp="/tmp/gnome-shell"
    local gmd_theme_path="/usr/share/themes/Catppuccin-Orange-Dark/gnome-shell"
    local background_wall="/usr/share/backgrounds/catcat-os/altos_odyssey_blurred.jpg"
    local gdm_xml="$(basename ${gdm_resource}).xml"
    local resource resource_path

    log "INFO" "Using GTK theme: $(basename $(dirname ${gmd_theme_path}))"
    # Create directories and extract resources from gresource file
    log "INFO" "Creating directories and extracting resources from gresource file"
    for resource in $(gresource list "${gdm_resource}"); do
        resource_path="${resource#\/org\/gnome\/shell\/}"
        mkdir -vp "${gmd_theme_tmp}/${resource_path%/*}"
        gresource extract "${gdm_resource}" "${resource}" > "${gmd_theme_tmp}/${resource_path}"
    done

    # Copy custom theme files and background wallpaper to working directory
    log "INFO" "Copying custom theme files and background wallpaper to working directory"
    cp -drvf "${gmd_theme_path}"/* "${gmd_theme_tmp}/theme"/
    cp -dvf "${background_wall}" "${gmd_theme_tmp}/theme/background"

    # Set background wallpaper and modify CSS for login and lock screen
    log "INFO" "Setting background wallpaper and modifying CSS for login and lock screen"
    echo ".login-dialog { background: transparent; }
#lockDialogGroup {
  background-image: url('resource:///org/gnome/shell/theme/background');
  background-position: center;
  background-size: cover;
}" >> "${gmd_theme_tmp}/theme/gnome-shell.css"

    # Ensure the same CSS is used for both light and dark modes
    log "INFO" "Applying custom theme CSS on both light and dark modes"
    cp -drvf "${gmd_theme_tmp}/theme/gnome-shell.css" "${gmd_theme_tmp}/theme/gnome-shell-dark.css"
    cp -drvf "${gmd_theme_tmp}/theme/gnome-shell.css" "${gmd_theme_tmp}/theme/gnome-shell-light.css"

    # Generate gresource XML file for compiling resources
    log "INFO" "Generating gresource XML file for compiling resources"
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<gresources>
  <gresource prefix=\"/org/gnome/shell/theme\">
$(find "${gmd_theme_tmp}/theme"/ -type f -not -wholename '*.gresource*' -printf '    <file>%P</file>\n')
  </gresource>
</gresources>" > "${gmd_theme_tmp}/theme/${gdm_xml}"
    cat "${gmd_theme_tmp}/theme/${gdm_xml}"

    # Compile all resources and apply them to the gdm theme
    log "INFO" "Compiling all resources and apply them to the gdm theme"
    glib-compile-resources --sourcedir="${gmd_theme_tmp}/theme"/ "${gmd_theme_tmp}/theme/${gdm_xml}"
    mv -v "${gmd_theme_tmp}/theme/$(basename ${gdm_resource})" "${gdm_resource}"

    rm -rf "${gmd_theme_tmp}"

    # Default settings for gdm
    log "INFO" "Getting default settings for GDM"
    cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/

    # TODO: build gdm theme in path /usr/local/share/gnome-shell when uncommenting below code
    # To allow GDM re-theming
#    log "INFO" "Allowing GDM re-theming"
#    mv -v   "${gdm_resource}" "${gdm_resource}.og"
#    ln -svf "/usr/local/share/gnome-shell/$(basename ${gdm_resource})" "${gdm_resource}"

    log "INFO" "All done"
    log "INFO" "Custom theme has been built and set for GDM"
}

apply_default_configs() {
    # Set default icon and theme
    log "INFO" "Setting default icons and theme for the OS"

    sed -i 's/Inherits=.*/Inherits=Catppuccin-Papirus-Orange/' /usr/share/icons/default/index.theme

    cp -drf /usr/share/themes/Catppuccin-Orange-Dark/{gtk-2.0,gtk-3.0,gtk-4.0} \
                            /usr/share/themes/Default/
    cp -drf /usr/share/themes/Catppuccin-Orange-Dark/gtk-4.0 /etc/skel/.config/

    mkdir -vp /etc/skel/.config/dconf
    /usr/bin/dconf update

    log "INFO" "Done"
    log "INFO" "Tree of: /etc/dconf"
    tree /etc/dconf/
}

install_vscodium_ext() {
    log "INFO" "Install extensions for vscodium"
    # Install extensions for vscodium
    local vscodium_extlist=(
        "jeronimoekerdt.color-picker-universal"
        "catppuccin.catppuccin-vsc"
        "catppuccin.catppuccin-vsc-icons"
    )

    mkdir -vp /tmp/vscodiumdata /etc/skel/.vscode-oss/extensions
    for vsc_ext in "${vscodium_extlist[@]}"; do
        codium --no-sandbox --user-data-dir /tmp/vscodiumdata --extensions-dir \
                            /etc/skel/.vscode-oss/extensions --install-extension "${vsc_ext}"
    done
    rm -rf /tmp/vscodiumdata
    log "INFO" "Installed vscodium extensions"
}

gnome_shell_ext() {
    log "INFO" "Copying gnome shell extensions to system default path"
    cp -drf /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/
    log "INFO" "Gnome shell extensions copied"
}

desktop_files
set_plymouth_theme
install_fonts
install_icon_themes
install_gtk_themes
build_gdm_theme
apply_default_configs
#install_vscodium_ext
gnome_shell_ext
