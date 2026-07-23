_check_local_config

# PATHS
set paths_to_add "/usr/games" "$HOME/.bin" "$HOME/.local/bin" "$HOME/.local/sbin" "$HOME/.local/podman/bin" "$HOME/.cargo/bin" "$HOME/Android/platform-tools" "$HOME/Android/cmdline-tools/bin"

for path in $paths_to_add
  if not contains -- $path $PATH
    set --prepend --path PATH "$path"
  end
end

set -e path
set -e paths_to_add
