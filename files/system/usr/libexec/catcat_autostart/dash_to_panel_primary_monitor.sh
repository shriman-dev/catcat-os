#!/usr/bin/bash
# Set primary monitor for dash to panel
usr_dconf_ext="/usr/etc/dconf/db/distro.d/extensions"
dash_to_panel_positions="$(dconf read /org/gnome/shell/extensions/dash-to-panel/panel-positions)"

if [[ -n "${DISPLAY}" && "${dash_to_panel_positions}" =~ '"":' ]]; then
    primary_monitor="$(gdbus call --session --dest org.gnome.Mutter.DisplayConfig --object-path /org/gnome/Mutter/DisplayConfig --method org.gnome.Mutter.DisplayConfig.GetCurrentState | grep -o "\[((.*), \[(" | tr -cd '[:alnum:],' | cut -d "," -f2,4 | tr "," "-")"

    if [[ ! "${dash_to_panel_positions}" =~ "${primary_monitor}" ]]; then

        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-sizes \
            $(grep -E "^panel-sizes=.*$" "${usr_dconf_ext}" | \
                sed "s|panel-sizes='{\".*\":|panel-sizes='{\"${primary_monitor}\":|" | \
                    sed "s|panel-sizes=||")

        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-element-positions \
            $(grep -E "^panel-element-positions=.*$" "${usr_dconf_ext}" | \
                sed "s|panel-element-positions='{\".*\":\[{\"|panel-element-positions='{\"${primary_monitor}\":\[{\"|" | \
                    sed "s|panel-element-positions=||")

        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-positions \
            $(grep -E "^panel-positions=.*$" "${usr_dconf_ext}" | \
                sed "s|panel-positions='{\".*\":|panel-positions='{\"${primary_monitor}\":|" | \
                    sed "s|panel-positions=||")

    fi
fi

