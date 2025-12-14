test -f $HOME/.config/fish/conf.d/path.fish && status filename | grep -q 'vendor_conf.d' && exit 0
# PATHS
set -g paths_to_add "/usr/games" "$HOME/.bin" "$HOME/.local/bin" "$HOME/.local/sbin" "$HOME/.local/podman/bin" "$HOME/.cargo/bin" "$HOME/Android/platform-tools" "$HOME/Android/cmdline-tools/bin"

for path in $paths_to_add
  if not contains -- $path $PATH
    set -g PATH "$path:$PATH"
  end
end

