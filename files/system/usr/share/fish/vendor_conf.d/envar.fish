test -f $HOME/.config/fish/conf.d/envar.fish && status filename | grep -q 'vendor_conf.d' && exit 0
# Hide welcome message
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"

#set -x QT_QPA_PLATFORMTHEME "qt5ct"
#set -x QT_QPA_PLATFORM "xcb"
set -x MICRO_TRUECOLOR 1
set -x NIXPKGS_ALLOW_UNFREE 1
set -x ni "$HOME/.local/state/nix/profiles/profile/bin"

# Set var for android home
if test -d $HOME/.local/share/waydroid/data/media/0
  set -x ANH "$HOME/.local/share/waydroid/data/media/0"
else
  set -x ANH "/storage/emulated/0"
end

# Set bat command as manpager for syntax highlighting
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# python ta-lib
set -x TA_INCLUDE_PATH "$HOME/.local/state/nix/profiles/profile/include"
set -x TA_LIBRARY_PATH "$HOME/.local/state/nix/profiles/profile/lib"


