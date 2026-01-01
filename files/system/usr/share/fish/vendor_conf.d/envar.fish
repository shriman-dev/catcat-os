_check_local_config
# Hide welcome message
set -g fish_greeting ""

set -gx NIXPKGS_ALLOW_UNFREE 1
set -gx ni "$HOME/.local/state/nix/profiles/profile/bin"

# Set var for android home
if test -d /storage/emulated/0
  set -gx ANHOME "/storage/emulated/0"
end
if test -d $HOME/.local/share/waydroid/data/media/0
  set -gx ANHOME "$HOME/.local/share/waydroid/data/media/0"
end

# Set bat command as manpager for syntax highlighting
set -gx MANROFFOPT "-c"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
