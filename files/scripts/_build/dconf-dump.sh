#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DCONF_DIR="$(dirname $(dirname $SCRIPT_DIR))/files/dconf"

dconfDump() {
    local path=$1
    local extraSed=$2
    local fileToDumpOutput=$3
    dconf dump "$path" | sed "s|^\[\([^][]\+\)|\[${path:1}\1|;s|//\]|\]|;$extraSed" >> "$fileToDumpOutput"
    echo >> "$fileToDumpOutput"
}

# keybindings
> $DCONF_DIR/keybindings
dconfDump '/org/gnome/desktop/wm/keybindings/' "" $DCONF_DIR/keybindings
dconfDump '/org/gnome/shell/keybindings/' "" $DCONF_DIR/keybindings
dconfDump '/org/gnome/mutter/keybindings/' "" $DCONF_DIR/keybindings
dconfDump '/org/gnome/mutter/wayland/keybindings/' "" $DCONF_DIR/keybindings
dconfDump '/org/gnome/settings-daemon/plugins/media-keys/' "" $DCONF_DIR/keybindings

# input
> $DCONF_DIR/input
#dconfDump '/org/gnome/desktop/input-sources/' "" $DCONF_DIR/input
dconfDump '/org/freedesktop/ibus/engine/typing-booster/' "" $DCONF_DIR/input

# apps
declare -A appPathsWithSed=(
    ['/com/github/donadigo/appeditor/']="
/window-/d
/selected-/d"
    ['/org/fedoraproject/FirewallConfig/']=""
    ['/org/gnome/gnome-system-monitor/']="
/current-tab/d
/cpu-colors/d
/window-/d"
    ['/org/gnome/nautilus/']="
/window-state/,/^$/d
/type-ahead-search/d
/default-compression-format/d"
    ['/org/nemo/']="
s/side-pane-view=.*/side-pane-view='tree'/
/geometry/d"
    ['/org/gnome/Ptyxis/']="
/window-size=(/d"
    ['/org/gnome/software/']="
/flatpak-purge-timestamp/d"
    ['/org/x/editor/']="
/\/filebrowser\//,/^$/d
/editor\/state/,/^$/ { /size/d; /state/d }"
)

> $DCONF_DIR/apps
for path in "${!appPathsWithSed[@]}"; do
    dconfDump "$path" "${appPathsWithSed[$path]}" "$DCONF_DIR/apps"
done


#/bedtime-mode/,/^$/ { /bedtime-mode-active/d }
# extensions
declare -A extensionPathsWithSed=(
    ['/com/github/amezin/ddterm/']=""
    ['/io/github/jeffshee/hanabi-extension/']="
s|video-path=.*|video-path='/usr/share/backgrounds/catcat-os/altos-odyssey-live.mp4'|"
    ['/org/gnome/shell/extensions/blur-my-shell/']=""
    ['/org/gnome/shell/extensions/caffeine/']="
/cli-toggle/d
/toggle-state/d
/user-enabled/d
/indicator-position-max/d"
    ['/org/gnome/shell/extensions/clipboard-history/']=""
    ['/org/gnome/shell/extensions/custom-hot-corners-extended/']=""
    ['/org/gnome/shell/extensions/dash-to-panel/']="
/dash-to-panel/,/^$/ { s/\"A.*-.*[0-9]\"/\"\"/ }
/dash-to-panel/,/^$/ { /primary-monitor=/d }"
    ['/org/gnome/shell/extensions/default-workspace/']=""
    ['/org/gnome/shell/extensions/forge/']=""
    ['/org/gnome/shell/extensions/notification-timeout/']=""
    ['/org/gnome/shell/extensions/vitals/']="
s/hot-sensors=.*/hot-sensors=\['__temperature_avg__', '_processor_usage_', '_memory_allocated_', '__network-tx_max__', '__network-rx_max__'\]/"
    ['/org/gnome/shell/extensions/user-theme/']=""
)

echo -e "\n[org/gnome/shell]
enabled-extensions=['blur-my-shell@aunetx', 'caffeine@patapon.info', 'clipboard-history@alexsaveau.dev', 'custom-hot-corners-extended@G-dH.github.com', 'dash-to-panel@jderose9.github.com', 'forge@jmmaranan.com', 'hide-universal-access@akiirui.github.io', 'notification-timeout@chlumskyvaclav.gmail.com', 'drive-menu@gnome-shell-extensions.gcampax.github.com', 'Vitals@CoreCoding.com', 'user-theme@gnome-shell-extensions.gcampax.github.com']\n" > $DCONF_DIR/extensions

for path in "${!extensionPathsWithSed[@]}"; do
    dconfDump "$path" "${extensionPathsWithSed[$path]}" "$DCONF_DIR/extensions"
done


# background
> $DCONF_DIR/background
dconfDump '/org/gnome/desktop/background/' "s|file://.*|file:///usr/share/backgrounds/catcat-os/altos_odyssey.jpg'|" $DCONF_DIR/background

# interface
> $DCONF_DIR/interface
dconfDump '/org/gnome/desktop/interface/' "" $DCONF_DIR/interface

# wmpreferences
> $DCONF_DIR/wmpreferences
dconfDump '/org/gnome/desktop/wm/preferences/' "" $DCONF_DIR/wmpreferences
dconfDump '/org/gnome/mutter/' "/output-luminance/d" $DCONF_DIR/wmpreferences


# shell
declare -A shellPathsWithSed=(
    ['/org/gnome/shell/']="
s|favorite-apps=.*|favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Ptyxis.desktop', 'io.gitlab.librewolf-community.desktop', 'io.freetubeapp.FreeTube.desktop', 'page.kramo.Cartridges.desktop']|
/shell\/extensions/,\$d
/command-history/d
/enabled-extensions/d
/disabled-extensions/d
/last-selected-power-profile/d
/remember-mount-password/d
/looking-glass-history/d
/welcome-dialog-last-shown-version/d
/had-bluetooth-devices-setup/d
/^app-picker-layout=/s/,[^,]*\.desktop[^,]*>//g
s|'quick-touchpad-toggle@kramo.hu',||;s|, 'quick-touchpad-toggle@kramo.hu'||
s|'color-picker@tuberry',||;s|, 'color-picker@tuberry'||
s|'syncthing@gnome.2nv2u.com',||;s|, 'syncthing@gnome.2nv2u.com'||"
    ['/org/gnome/shell/window-switcher/']=""
)

> $DCONF_DIR/shell
for path in "${!shellPathsWithSed[@]}"; do
    dconfDump "$path" "${shellPathsWithSed[$path]}" "$DCONF_DIR/shell"
done


# defaults
declare -A defaultPathsWithSed=(
    ['/org/freedesktop/tracker/']="
/index-recursive-directories=/d"
    ['/org/gnome/desktop/a11y/']="
/screen-magnifier-enabled=/d"
    ['/org/gnome/desktop/datetime/']=""
    ['/org/gnome/desktop/peripherals/']="
/peripherals\/keyboard/,/^$/ { /numlock-state=/d }"
    ['/org/gnome/desktop/privacy/']=""
    ['/org/gnome/desktop/screensaver/']=""
    ['/org/gnome/desktop/search-providers/']=""
    ['/org/gnome/desktop/session/']=""
    ['/org/gnome/desktop/sound/']=""
    ['/org/gnome/login-screen/']="
s|message-text=.*|message-text='Meow'|"
    ['/org/gnome/settings-daemon/']="
/media-keys/,/^$/d
/touchscreen/,/^$/d
/global-shortcuts/,/^$/d
/sleep-inactive-ac-type/d
/donation-reminder-last-shown/d
/sleep-inactive-battery-type/d
/night-light-enabled/d
/night-light-temperature/d"
    ['/org/gnome/system/location/']=""
    ['/org/gtk/gtk4/settings/file-chooser/']="
/window-/d"
    ['/org/gtk/settings/file-chooser/']="
/window-/d
/last-folder-uri/d"
)

> $DCONF_DIR/defaults
for path in "${!defaultPathsWithSed[@]}"; do
    dconfDump "$path" "${defaultPathsWithSed[$path]}" "$DCONF_DIR/defaults"
done

sh -c "echo '
[org/gnome/desktop/notifications]
show-in-lock-screen=false
' >> $DCONF_DIR/defaults"


