_check_local_config
# Hide welcome message
set -g fish_greeting

# Set bat command as manpager for syntax highlighting
set -gx MANROFFOPT "-c"
set -gx MANPAGER "sh -c 'col -bx | bat --language man --style=plain --paging=always'"

set -gx NIXPKGS_ALLOW_UNFREE 1

# Set var for android home
if test -d /storage/emulated/0
    set -gx ANHOME "/storage/emulated/0"
end
if test -d $HOME/.local/share/waydroid/data/media/0
    set -gx ANHOME "$HOME/.local/share/waydroid/data/media/0"
end

if not test -d $HOME/.config/bat
    set -gx BAT_CONFIG_DIR /etc/bat
end

if not test -d $HOME/.config/eza
    set -gx EZA_CONFIG_DIR /etc/eza
end

if not test -d $HOME/.config/yazi
    set -gx YAZI_CONFIG_HOME /etc/yazi
end

set -gx PROCS_CONFIG_FILE $HOME/.config/procs/config.toml
if not test -f $PROCS_CONFIG_FILE
    set -gx PROCS_CONFIG_FILE /etc/procs/config.toml
end

set -gx BOTTOM_CONFIG_FILE $HOME/.config/bottom/bottom.toml
if not test -f $BOTTOM_CONFIG_FILE
    set -gx BOTTOM_CONFIG_FILE /etc/bottom/bottom.toml
end
