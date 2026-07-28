#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail
SYS_CACHE="${BUILD_CACHE_DIR}/system-theming"

desktop_files() {
    log "INFO" "Configuring desktop files"

    local desktopfile_dir="/usr/share/applications"
    # To use catcat update
    sed -i "s|^Exec=.*|Exec=/usr/bin/sudo /usr/bin/update all|" "${desktopfile_dir}"/system-update.desktop || true

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
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/fish.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/bottom.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/yad-icon-browser.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/nvtop.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/amdgpu_top.desktop || true
    sed -i "/NoDisplay/d;/\[Desktop Entry\]/a NoDisplay=true" "${desktopfile_dir}"/amdgpu_top-tui.desktop || true

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

#        ['FontAwesome']="\
#$(latest_ghpkg_url 'FortAwesome/Font-Awesome' 'desktop\.zip')"

#        ['NotoColorEmoji']="\
#https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
    )

    log "INFO" "Installing Extra Font(s)"
    local FONTS_DIR="${SYS_CACHE}/usr/share/fonts" TMP_DIR="/tmp/extra_fonts"
    local font_name font_url
    for font_name in "${!EXTRA_FONTS[@]}"; do
        font_url="${EXTRA_FONTS[${font_name}]}"
        font_name=${font_name// /} # remove spaces
        get_fonts "${font_name}" "${font_url}"
    done
    rm -rf "${TMP_DIR}"
    log "INFO" "Extra Font(s) installed"
}

install_icon_themes() {
    log "INFO" "Installing icons"
    local ICONS_DIR="${SYS_CACHE}/usr/share/icons"

    mkdir -vp "${ICONS_DIR}"
    if [[ -d "${ICONS_DIR}/Papirus" ]]; then
        log "NOTE" "Icons skipped - Non-empty directory(s) exists: ${ICONS_DIR}/Papirus"
    else
        log "INFO" "Papirus icons"
        local JQ_FILTER='.tarball_url'
        local latest_icons_url="$(latest_ghpkg_url 'PapirusDevelopmentTeam/papirus-icon-theme')"
        local icons_archive="/tmp/icons/$(basename ${latest_icons_url}).tar"

        mkdir -vp "$(dirname ${icons_archive})"
        curl_get "${icons_archive}" "${latest_icons_url}"
        unarchive "${icons_archive}" "${icons_archive}.extract" >/dev/null

        local papirus_subd papirus_dir
        find "${icons_archive}.extract" -type d -name "24x24" | while read -r papirus_subd; do
            papirus_dir="$(dirname ${papirus_subd})"
            ocopy "${papirus_dir}" "${ICONS_DIR}/$(basename ${papirus_dir})"
        done
    fi

    rm -rf /tmp/icons
    log "INFO" "Icons installed"
}

install_gtk_themes() {
    log "INFO" "Installing GTK theme(s)"
    local THEMES_DIR="${SYS_CACHE}/usr/share/themes"

    mkdir -vp "${THEMES_DIR}"
    # Lavanda-gtk-theme
    if [[ -d "${THEMES_DIR}/Lavanda-Dark" ]]; then
        log "NOTE" "Theme skipped - Non-empty directory(s) exists: ${THEMES_DIR}/Lavanda-Dark"
    else
        log "INFO" "Lavanda-gtk-theme"
        local JQ_FILTER='.tarball_url'
        local latest_lavanda_url="$(latest_ghpkg_url 'vinceliuice/Lavanda-gtk-theme')"
        local lavanda_tar="/tmp/themes/$(basename ${latest_lavanda_url}).tar"

        mkdir -vp "$(dirname ${lavanda_tar})"
        curl_get "${lavanda_tar}" "${latest_lavanda_url}"
        unarchive "${lavanda_tar}" "${lavanda_tar}.extract" >/dev/null

        chmod -v +x "${lavanda_tar}.extract"/*/install.sh
        "${lavanda_tar}.extract"/*/install.sh --dest "${THEMES_DIR}" --color light dark
    fi

    # Catppuccin-Gtk-Theme
    if [[ -d "${THEMES_DIR}/Catppuccin-Dark" ]]; then
        log "NOTE" "Theme skipped - Non-empty directory(s) exists: ${THEMES_DIR}/Catppuccin-Dark"
    else
        log "INFO" "Catppuccin-Gtk-Theme"
        local catppuccin_theme_repo="https://github.com/shriman-dev/Catppuccin-Gtk-Theme.git"
        local catppuccin_theme_tmp="/tmp/themes/Catppuccin-Gtk-Theme"

        git clone --depth 1 "${catppuccin_theme_repo}" "${catppuccin_theme_tmp}"
        chmod -v +x "${catppuccin_theme_tmp}"/install.sh
        "${catppuccin_theme_tmp}"/install.sh --dest "${THEMES_DIR}" --name 'Catppuccin' --theme all \
                                             --color dark --tweaks catppuccin rimless
    fi
    rm -rf /tmp/themes
    log "INFO" "GTK theme(s) installed"
}

build_gdm_theme() {
    log "INFO" "Building GDM theme"

    local gdm_resource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
    local gmd_theme_tmp="/tmp/gnome-shell"
    local gmd_theme_path="${SYS_CACHE}/usr/share/themes/Catppuccin-Orange-Dark/gnome-shell"
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
    cp -vaf "${gmd_theme_path}"/* "${gmd_theme_tmp}/theme"/
    cp -vf "${background_wall}" "${gmd_theme_tmp}/theme/background"

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
    cp -vf "${gmd_theme_tmp}/theme/gnome-shell.css" "${gmd_theme_tmp}/theme/gnome-shell-dark.css"
    cp -vf "${gmd_theme_tmp}/theme/gnome-shell.css" "${gmd_theme_tmp}/theme/gnome-shell-light.css"

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
    cp -vaf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/

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

    local default_gtk_theme="${SYS_CACHE}/usr/share/themes/Catppuccin-Orange-Dark"
    cp -af "${default_gtk_theme}"/{gtk-2.0,gtk-3.0,gtk-4.0} /usr/share/themes/Default/
    cp -af "${default_gtk_theme}/gtk-4.0" /etc/skel/.config/

    mkdir -vp /etc/skel/.config/dconf
    /usr/bin/dconf update

    log "INFO" "Done"
    log "INFO" "Tree of: /etc/dconf"
    tree /etc/dconf/
}

#install_vscodium_ext() {
#    log "INFO" "Install extensions for vscodium"
#    # Install extensions for vscodium
#    vsc_ext_dir="${SYS_CACHE}/etc/skel/.vscode-oss/extensions"
#    local vscodium_extlist=(
#        "jeronimoekerdt.color-picker-universal"
#        "catppuccin.catppuccin-vsc"
#        "catppuccin.catppuccin-vsc-icons"
#    )

#    mkdir -vp /tmp/vscodiumdata "${vsc_ext_dir}"
#    for vsc_ext in "${vscodium_extlist[@]}"; do
#        codium --no-sandbox --user-data-dir /tmp/vscodiumdata --extensions-dir \
#                            "${vsc_ext_dir}" --install-extension "${vsc_ext}"
#    done
#    rm -rf /tmp/vscodiumdata
#    log "INFO" "Installed vscodium extensions"
#}

gnome_shell_ext() {
    log "INFO" "Copying gnome shell extensions to system default path"
    ocopy /etc/skel/.local/share/gnome-shell/extensions /usr/share/gnome-shell/extensions
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

log "INFO" "Copying cached files"
ocopy "${SYS_CACHE}" /
fc-cache --system-only --really-force "/usr/share/fonts"
