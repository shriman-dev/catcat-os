# Enable or Disable Gnome Extension
[group("gnome desktop")]
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}

# Restore Gnome DE settings
[group("gnome desktop")]
restore-gnome-de-settings:
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome settings..."
    rm -rf "${HOME}/.config/dconf"
    dconf reset -f /
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Restore applications grid folders
[group("gnome desktop")]
restore-gnome-folders:
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome folders..."
    dconf reset -f /org/gnome/desktop/app-folders/
    dconf reset /org/gnome/shell/app-picker-layout
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Revert any Gnome restoration made using "ucat restore-gnome-*"
[group("gnome desktop")]
revert-gnome-restoration:
    #!/usr/bin/bash
    if [[ -d "${HOME}/.config/dconf.bak" ]]; then
        echo "Reverting gnome settings..."
        mv "${HOME}/.config/dconf" "${HOME}/.config/dconf.before.revert"
        cp -af "${HOME}/.config/dconf.bak" "${HOME}/.config/dconf"
        echo "Done."
        echo "You may need to log out and log in again for the changes to take effect."
    else
        echo "It is possible gnome settings backup was failed during previous restoration."
        echo "Or restoration was never performed."
    fi
