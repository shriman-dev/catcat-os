# Automatic updates only on specific connection. Connection types: ethernet or wifi. For specific Wi-Fi network use 'wifi=<SSID>'
[group("network")]
auto-update-on-connection CONNECTION:
    #!/usr/bin/env -S sudo -- /bin/bash
    CONNECTION={{ CONNECTION }}
    mkdir -p /etc/catcat-os
    echo "${CONNECTION}" > /etc/catcat-os/auto_update_on_connection

# Toggle SSH
[group("network")]
toggle-ssh ACTION="":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    OPTION="{{ ACTION }}"
    # Get hostname and IP address
    HOSTNAME="$(hostname)"
    IP_ADDRESS="$(hostname -I | awk '{print $1}')" # First IP address
    # Get current SSH status
    SSH_STATUS_RUNNING="$(systemctl is-active sshd)"
    SSH_STATUS="${yellow}Disabled And ${SSH_STATUS_RUNNING^}${normal}"
    if systemctl is-enabled --quiet sshd; then
        SSH_STATUS="${green}Enabled And ${SSH_STATUS_RUNNING^}${normal}"
    fi
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
        echo -e "${bold}SSH Status:${normal} ${SSH_STATUS}\n"
        # Prompt user for action
        echo -e "${bold}Choose an option:${normal}"
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
            echo ""
            ;;
        "Mask and Disable SSH"|disable)
            log "INFO" "Disabling SSH on boot..."
            sudo systemctl disable sshd.service sshd-unix-local.socket sshd-vsock.socket
            sudo systemctl stop sshd.service sshd-unix-local.socket
            sudo systemctl mask sshd.service sshd.socket sshd-unix-local.socket sshd-vsock.socket
            echo -e "SSH is now ${yellow}Masked and Disabled${normal}."
            echo ""
            ;;
        "Enable SSH Persistently"|enable)
            log "INFO" "Enabling SSH on boot..."
            sudo systemctl unmask sshd.service sshd.socket sshd-unix-local.socket sshd-vsock.socket
            sudo systemctl enable sshd.service
            sudo systemctl start  sshd.service sshd-unix-local.socket
            echo -e "SSH is now ${green}Enabled${normal}. You can SSH using:"
            echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
            echo ""
            ;;
        *)
            log "INFO" "No changes made."
            ;;
    esac

# Toggle IWD
[group("network")]
toggle-iwd ACTION="":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    OPTION="{{ ACTION }}"
    IWD_CONF="/etc/NetworkManager/conf.d/iwd.conf"
    # Get current IWD status
    IWD_STATUS_RUNNING="$(systemctl is-active iwd.service)"
    IWD_STATUS="${yellow}Disabled And ${IWD_STATUS_RUNNING^}${normal}"
    if systemctl is-enabled --quiet iwd.service; then
        IWD_STATUS="${green}Enabled And ${IWD_STATUS_RUNNING^}${normal}"
    fi

    # Explain the purpose of the script
    echo -e "IWD as a replacement for wpa_supplicant for Wi-Fi."
    echo -e "Enabling can improve throughput, mesh net and reduce latency when scanning for networks."
    echo -e "Disabling can improve functionality on some wifi adapters."
    echo -e ""
    log "WARN" "Changing this will remove all saved wifi networks"

    if [[ "${OPTION}" == "help" ]]; then
        echo "Usage: ucat toggle-iwd <option>"
        echo "  <option>: Specify the option to skip the interactive prompt"
        echo "  Use 'enable' to enable IWD service persistently on boot"
        echo "  Use 'disable' to mask and disable IWD service"
        exit 0
    elif [[ "${OPTION}" == "" ]]; then
        # Display current status
        echo -e "${bold}IWD Status:${normal} ${IWD_STATUS}\n"
        # Prompt user for action
        echo -e "${bold}Choose an option:${normal}"
        OPTION=$(ugum choose "Enable IWD Persistently" \
                             "Mask and Disable IWD" \
                             "Exit Without Saving")
    fi

    remove_saved_networks() {
        nmcli -t -f NAME connection show | while read -r line; do
            sudo nmcli connection delete "${line}"
        done
    }

    case "${OPTION}" in
        "Mask and Disable IWD"|disable)
            log "INFO" "Disabling IWD..."
            sudo rm -f "${IWD_CONF}"
            sudo systemctl mask iwd.service
            sudo systemctl unmask wpa_supplicant.service
            remove_saved_networks
            echo -e "IWD is now ${yellow}Masked and Disabled${normal}."
            echo -e "Reboot required to apply changes."
            echo ""
            ;;
        "Enable IWD Persistently"|enable)
            log "INFO" "Enabling IWD..."
            sudo rm -f "${IWD_CONF}"
            ensure_dir "$(dirname ${IWD_CONF})"
            printf "[device]\nwifi.backend=iwd\nwifi.iwd.autoconnect=yes" | \
                sudo tee "${IWD_CONF}" > /dev/null
            sudo systemctl mask wpa_supplicant.service
            sudo systemctl unmask iwd.service
            remove_saved_networks
            echo -e "IWD is now ${green}Enabled${normal}"
            echo -e "Reboot required to apply changes."
            echo ""
            ;;
        *)
            log "INFO" "No changes made."
            ;;
    esac
