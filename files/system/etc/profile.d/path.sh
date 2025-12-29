paths_to_add=("/usr/games" "${HOME}/.bin" "${HOME}/.local/bin" "${HOME}/.local/sbin" "${HOME}/.local/podman/bin" "${HOME}/.cargo/bin" "${HOME}/Android/platform-tools" "${HOME}/Android/cmdline-tools/bin")

for path in "${paths_to_add[@]}"; do
  if [[ ! ${PATH} =~ "${path}" ]]; then
    export PATH="${path}:${PATH}"
  fi
done
