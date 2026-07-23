# Automatic updates only on specific connection. Connection types: ethernet or wifi. For specific Wi-Fi network use 'wifi=<SSID>'
[group("network")]
auto-update-on-connection CONNECTION:
    #!/usr/bin/env -S sudo -- /bin/bash
    CONNECTION={{ CONNECTION }}
    mkdir -p /etc/catcat-os/
    echo "${CONNECTION}" > /etc/catcat-os/auto_update_on_connection

# Toggle SSH
[group("network")]
toggle-ssh ACTION="":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    # Get hostname and IP address
    HOSTNAME=$(hostname)
    IP_ADDRESS=$(hostname -I | awk '{print $1}') # First IP address
    # Get current SSH status
    SSH_STATUS_RUNNING=$(systemctl is-active sshd)
    SSH_STATUS="Disabled And ${SSH_STATUS_RUNNING[@]^}"
    if systemctl is-enabled --quiet sshd; then
      SSH_STATUS="Enabled And ${SSH_STATUS_RUNNING[@]^}"
    fi
    OPTION="{{ ACTION }}"
    if [[ "${OPTION}" == "help" ]]; then
      echo "Usage: ucat toggle-ssh <option>"
      echo "  <option>: Specify the option to skip the interactive prompt"
      echo "  Use 'start' to start SSH service till next reboot"
      echo "  Use 'enable' to enable SSH service persistently on boot"
      echo "  Use 'disable' to mask and disable SSH service"
      exit 0
    elif [[ "${OPTION}" == "" ]]; then
      # Display current status
      echo -e "\n${bold}Hostname:${normal} ${HOSTNAME}"
      echo -e "${bold}IP Address:${normal} ${IP_ADDRESS}"
      if [[ "${SSH_STATUS}" == "Enabled" ]]; then
        echo -e "${bold}SSH Status:${normal} ${green}${SSH_STATUS}${normal}\n"
      else
        echo -e "${bold}SSH Status:${normal} ${yellow}${SSH_STATUS}${normal}\n"
      fi
      # Prompt user for action
      echo "Choose an option:"
      OPTION=$(ugum choose "Start SSH Till Next Reboot" \
                           "Enable SSH Persistently" \
                           "Mask and Disable SSH" \
                           "Exit Without Saving")
    fi
    case "${OPTION}" in
      "Start SSH Till Next Reboot"|start)
        log "INFO" "Starting SSH till next reboot..."
        sudo systemctl unmask sshd.service sshd.socket sshd-unix-local.socket sshd-vsock.socket
        sudo systemctl start  sshd.service sshd-unix-local.socket
        echo -e "SSH is now ${green}Started${normal}. You can SSH using:"
        echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
        echo " "
        ;;
      "Mask and Disable SSH"|disable)
        log "INFO" "Disabling SSH on boot..."
        sudo systemctl disable sshd.service sshd-unix-local.socket sshd-vsock.socket
        sudo systemctl stop sshd.service sshd-unix-local.socket
        sudo systemctl mask sshd.service sshd.socket sshd-unix-local.socket sshd-vsock.socket
        echo -e "SSH is now ${yellow}Masked and Disabled${normal}."
        echo " "
        ;;
      "Enable SSH Persistently"|enable)
        log "INFO" "Enabling SSH on boot..."
        sudo systemctl unmask sshd.service sshd.socket sshd-unix-local.socket sshd-vsock.socket
        sudo systemctl enable sshd.service
        sudo systemctl start  sshd.service sshd-unix-local.socket
        echo -e "SSH is now ${green}Enabled${normal}. You can SSH using:"
        echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
        echo " "
        ;;
      *)
        log "INFO" "No changes made."
        ;;
    esac

[group("network")]
iwd ACTION="":
    #!/usr/bin/bash
    get_status_token() {
      if [[ -f "/etc/NetworkManager/conf.d/iwd.conf" ]]; then
        echo "enable"
      else
        echo "disable"
      fi
    }

    OPTION={{ ACTION }}
    if [[ "${OPTION,,}" == "status" ]]; then
      get_status_token
      exit 0
    fi
    # Explain the purpose of the script
    echo -e "Enable or Disable iwd as a replacement for wpa_supplicant for Wi-Fi"
    echo -e "Enabling can improve throughput, mesh net and reduce latency when scanning for networks"
    echo -e "Disabling can improve functionality on some wifi adapters"
    echo -e ""
    echo -e "WARNING: Changing this will remove all saved wifi networks"
    get_current_status() {
      if [[ "$(get_status_token)" == "enable" ]]; then
        echo "Enabled"
      else
        echo "Disabled"
      fi
    }
    remove_saved_networks() {
        nmcli -t -f NAME connection show | while read -r line; do
            sudo nmcli connection delete "${line}"
        done
    }
    enable_iwd() {
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      printf "[device]\nwifi.backend=iwd\nwifi.iwd.autoconnect=yes" | \
        sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null
      sudo systemctl mask wpa_supplicant.service
      sudo systemctl unmask iwd.service
      remove_saved_networks
      echo -e "iwd enabled. Reboot required to apply changes."
    }
    disable_iwd() {
      sudo mkdir -p "/etc/NetworkManager/conf.d/"
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      sudo systemctl mask iwd.service
      sudo systemctl unmask wpa_supplicant.service
      remove_saved_networks
      echo -e "iwd disabled. Reboot required to apply changes."
    }
    # Show status
    current_status=$(get_current_status)
    echo -e "\nCurrent iwd status: ${current_status}\n"

    if [[ "${OPTION,,}" == "enable" ]]; then
      enable_iwd
      exit 0
    fi

    if [[ "${OPTION,,}" == "disable" ]]; then
      disable_iwd
      exit 0
    fi

    if [ -z "$OPTION" ]; then
      CHOICE=$(ugum choose "Enable iwd" "Disable iwd" "Exit without changes")
    else
      exit 0
    fi
    case "${CHOICE}" in
      "Enable iwd")
        enable_iwd
        ;;
      "Disable iwd")
        disable_iwd
        ;;
      "Exit without changes")
        echo "No changes made."
        ;;
      *)
        echo "Invalid choice. Exiting without changes."
        ;;
    esac

