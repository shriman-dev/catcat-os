CATCAT_CONF="${HOME}/.local/share/catcat-os"

[[ $(id -u) -eq 1000 ]] && {
    primary_monitor="$(gdbus call --session --dest org.gnome.Mutter.DisplayConfig --object-path /org/gnome/Mutter/DisplayConfig --method org.gnome.Mutter.DisplayConfig.GetCurrentState | grep -o "\[((.*), \[(" | tr -cd '[:alnum:],' | cut -d "," -f2,4 | tr "," "-")"
    echo "${primary_monitor}" > "${CATCAT_CONF}/primary-monitor"
}
