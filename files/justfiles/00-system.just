# Update system, flatpaks, and nixpkgs all at once
[group("system")]
update:
    #!/usr/bin/bash
    sudo /usr/bin/update all

# Update device firmware
[group("system")]
update-firmware:
    sudo /usr/bin/update firmware

# Turn automatic updates on or off
[group("system")]
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled --quiet catcat-os-update.timer; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic updates?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ucat toggle-updates <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable automatic updates."
      echo "  Use 'disable' to Disable automatic updates."
      exit 0
    fi
    if [[ "${OPTION,,}" == "enable" ]]; then
      sudo systemctl enable --force --now catcat-os-update.timer
    elif [[ "${OPTION,,}" == "disable" ]]; then
      sudo systemctl disable --force --now catcat-os-update.timer
    fi

# Turn automatic updates on or off
_toggle-updates:
    #!/usr/bin/bash
    ucat toggle-updates

