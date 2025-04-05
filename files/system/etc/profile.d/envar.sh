#export EDITOR="micro"
export MICRO_TRUECOLOR=1
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_QPA_PLATFORM=xcb
export QT_STYLE_OVERRIDE=kvantum
export GNOME_SHELL_SLOWDOWN_FACTOR=0.6
export JavaScriptCoreUseJIT=0 # https://trac.webkit.org/wiki/EnvironmentVariables
export GJS_DISABLE_JIT=1 # https://gitlab.gnome.org/GNOME/gjs/-/blob/master/doc/Environment.md

[[ ! -d $HOME/.config/bat ]] && export BAT_CONFIG_DIR="/etc/bat"
[[ ! -d $HOME/.config/eza ]] && export EZA_CONFIG_DIR="/etc/eza"
[[ ! -d $HOME/.config/yazi ]] && export YAZI_CONFIG_HOME="/etc/yazi"
[[ ! -f $HOME/.config/procs/config.toml ]] && export PROCS_CONFIG_FILE="/etc/procs/config.toml"
[[ -f $HOME/.config/procs/config.toml ]] && export PROCS_CONFIG_FILE="$HOME/.config/procs/config.toml"
