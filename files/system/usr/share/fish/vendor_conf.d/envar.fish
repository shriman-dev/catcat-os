test -f $HOME/.config/fish/conf.d/envar.fish && status filename | grep -q 'vendor_conf.d' && exit 0
# Hide welcome message
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"

set -gx NIXPKGS_ALLOW_UNFREE 1
set -gx ni "$HOME/.local/state/nix/profiles/profile/bin"

# Set var for android home
if test -d $HOME/.local/share/waydroid/data/media/0
  set -gx ANHOME "$HOME/.local/share/waydroid/data/media/0"
else
  set -gx ANHOME "/storage/emulated/0"
end

# Set bat command as manpager for syntax highlighting
set -gx MANROFFOPT "-c"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# python ta-lib
set -gx TA_INCLUDE_PATH "$HOME/.local/state/nix/profiles/profile/include"
set -gx TA_LIBRARY_PATH "$HOME/.local/state/nix/profiles/profile/lib"


