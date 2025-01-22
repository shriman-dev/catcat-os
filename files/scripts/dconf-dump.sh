#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DCONF_DIR="$( dirname $SCRIPT_DIR )/dconf"

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
/window-/d"
    ['/org/gnome/nautilus/']="
/window-state/,/^$/d
/type-ahead-search/d"
    ['/org/nemo/']="
/geometry/d"
    ['/org/gnome/Ptyxis/']="
/window-size=(/d"
    ['/org/gnome/software/']=""
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
    ['/org/gnome/shell/extensions/']="
/gsconnect/,/^$/d
/openbar/,/^$/d
s|right-box-order=\[.* 'syncthingIndicator'|right-box-order=\['Nothing to say indicator', 'syncthingIndicator'|
/color-picker/,/^$/ { /color-history/d }
/arcmenu/,/^$/ { /recently-installed-apps/d }
/burn-my-windows/,/^$/ { /active-profile/d }
/caffeine/,/^$/ { /toggle-state/d; /user-enabled/d }
/downfall/,/^$/ { /feature-enabled/d }
/Bluetooth-Battery-Meter/,/^$/ { /device-list/d }"
)

> $DCONF_DIR/extensions
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
dconfDump '/org/gnome/mutter/' "" $DCONF_DIR/wmpreferences


# shell
declare -A shellPathsWithSed=(
    ['/org/gnome/shell/']="
/shell\/extensions/,\$d
/command-history/d
/disabled-extensions/d
/last-selected-power-profile/d
/remember-mount-password/d
/looking-glass-history/d
/welcome-dialog-last-shown-version/d
/had-bluetooth-devices-setup/d
/^app-picker-layout=/s/,[^,]*\.desktop[^,]*>//g
s|'color-picker@tuberry',||
s|'syncthing@gnome.2nv2u.com',||
s|, 'color-picker@tuberry'||
s|, 'syncthing@gnome.2nv2u.com'||"
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
    ['/org/gnome/desktop/a11y/']=""
    ['/org/gnome/desktop/datetime/']=""
    ['/org/gnome/desktop/peripherals/']="
/peripherals\/keyboard/,/^$/ { /numlock-state=/d }"
    ['/org/gnome/desktop/privacy/']=""
    ['/org/gnome/desktop/screensaver/']=""
    ['/org/gnome/desktop/search-providers/']=""
    ['/org/gnome/desktop/sound/']=""
    ['/org/gnome/login-screen/']="
s|message-text=.*|message-text='Meow'|"
    ['/org/gnome/settings-daemon/']="
/media-keys/,/^$/d
/touchscreen/,/^$/d
/night-light-enabled/d
/night-light-temperature/d"
    ['/org/gnome/system/location/']=""
    ['/org/gtk/gtk4/settings/file-chooser/']="
/window-/d"
    ['/org/gtk/settings/file-chooser/']="
/window-/d"
)

> $DCONF_DIR/defaults
for path in "${!defaultPathsWithSed[@]}"; do
    dconfDump "$path" "${defaultPathsWithSed[$path]}" "$DCONF_DIR/defaults"
done

sh -c "echo '
[org/gnome/desktop/notifications]
show-in-lock-screen=false
' >> $DCONF_DIR/defaults"


