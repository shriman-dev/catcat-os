# Turn automatic nightly reboot on or off
[group("nightly reboot")]
toggle-nightly-reboot ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled --quiet nightly-reboot.timer; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic Nightly Reboot are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable Automatic Nightly Reboot?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ucat toggle-nightly-reboot <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable Automatic Nightly Reboot."
      echo "  Use 'disable' to Disable Automatic Nightly Reboot."
      exit 0
    fi
    if [[ "${OPTION,,}" == "enable" ]]; then
      sudo systemctl enable --force --now nightly-reboot.timer
    elif [[ "${OPTION,,}" == "disable" ]]; then
      sudo systemctl disable --force --now nightly-reboot.timer
    fi

# Cancel automatic nightly reboot sequence
[group("nightly reboot")]
cancel-nightly-reboot:
    #!/usr/bin/bash
    if [[ ! -d /run/NIGHTLY_REBOOT ]]; then
        echo "Nightly reboot was not sequenced correctly"
        exit 1
    fi
    echo "${USER}" | tee /run/NIGHTLY_REBOOT/user
    echo "Nightly reboot was cancelled by user: ${USER}" | tee /run/NIGHTLY_REBOOT/cancelled

