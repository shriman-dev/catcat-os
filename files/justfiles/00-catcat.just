# Show all logs from this boot
[group("logging")]
logs-this-boot:
    sudo journalctl --no-hostname -b 0

# Show all logs from last boot
[group("logging")]
logs-last-boot:
    sudo journalctl --no-hostname -b -1

# Show all the error logs
[group("logging")]
logs-errors:
    #!/usr/bin/bash
    sudo journalctl -p err

# Show selinux related logs
[group("logging")]
logs-selinux:
    #!/usr/bin/bash
    sudo sestatus
    echo ""
    sudo journalctl -t setroubleshoot

# Show warnings, errors and critical kernel/dmesg logs
[group("logging")]
logs-dmesg:
    #!/usr/bin/bash
    sudo dmesg -H -l warn,err,crit,alert,emerg

# Get logs for this boot and last boot, cleanly output in terminal
[group("logging")]
get-logs:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    # Get system status information
    echo -e "${bold}System Information:${normal}"
    echo " "
    rpm-ostree status
    echo " "
    # Get logs for this boot
    echo -e "${bold}Logs This Boot:${normal}"
    ujust logs-this-boot
    echo " "
    # Get logs for last boot
    echo -e "${bold}Logs Last Boot:${normal}"
    ujust logs-last-boot
    echo " "


# Analyze system boot time
boot-time-analyze:
    #!/usr/bin/bash
    systemd-analyze critical-chain
    echo ""
    systemd-analyze time

# Check for local overrides
check-local-overrides:
    #!/usr/bin/bash
    sudo ostree admin config-diff
    sudo diff -r \
             --suppress-common-lines \
             --color="always" \
             --exclude "passwd*" \
             --exclude "group*" \
             --exclude="subgid*" \
             --exclude="subuid*" \
             --exclude="machine-id" \
             --exclude="adjtime" \
             --exclude="fstab" \
             --exclude="system-connections" \
             --exclude="shadow*" \
             --exclude="gshadow*" \
             --exclude="ssh_host*" \
             --exclude="cmdline" \
             --exclude="crypttab" \
             --exclude="hostname" \
             --exclude="localtime" \
             --exclude="locale*" \
             --exclude="*lock" \
             --exclude=".updated" \
             --exclude="*LOCK" \
             --exclude="vconsole*" \
             --exclude="00-keyboard.conf" \
             --exclude="grub" \
             --exclude="system.control*" \
             --exclude="cdi" \
             --exclude="default.target" \
             --exclude="domains-blocklist.*" \
             /usr/etc /etc 2>/dev/null | sed '/Binary\ files\ /d' | rg --color=always --colors 'match:fg:yellow' --passthru 'Only in.*'

# Dump debug info
debug-info:
    #!/usr/bin/bash
    source /usr/lib/catcat/funcvar.sh
    sudo fastfetch
    symmetric_heading "Detailed Sys+Hardware Information" "="
    sudo inxi --basic --expanded -xxxa --verbosity 8
    symmetric_heading "50 System Package history" "="
    sudo rpm -qa --nodigest --nosignature --last | tac | tail -n50
    symmetric_heading "System flatpaks history" "="
    sudo flatpak --system history
    symmetric_heading "User flatpaks history" "="
    flatpak --user history
    symmetric_heading "50 System Package by Size" "="
    sudo rpm -qa --queryformat '%10{size} - %-25{name} \t %{version} \t %{os} \n' | \
            awk '{print $1/1024/1024 " MB", $2, $3, $4}' | sort -h | tail -n50
    symmetric_heading "System flatpaks by Size" "="
    sudo flatpak --system  list --columns=size,application | \
            awk '{gsub("[^[:alnum:]]","",$1); print $1 " - " $2}' | sort -h
    symmetric_heading "User flatpaks by Size" "="
    flatpak --user  list --columns=size,application | \
            awk '{gsub("[^[:alnum:]]","",$1); print $1 " - " $2}' | sort -h
    symmetric_heading "Recent System Events" "="
    sudo journalctl --no-pager -b -p err..alert --since "1 day ago"
    symmetric_heading "Selinux Info with Logs" "="
    sudo ujust log-selinux
    symmetric_heading "Listing Local Overrides" "="
    sudo ujust check-local-overrides
    symmetric_heading "Failed Services" "="
    sudo systemctl list-units --state=failed
    symmetric_heading "Last 50 Logins, Reboots and Shutdowns" "="
    last -x -n50
    symmetric_heading "Rpm-Ostree Status" "="
    sudo rpm-ostree status --verbose
    symmetric_heading "CatCat OS Changelog" "="
    sudo rpm-ostree db diff --changelogs

# Update system, flatpaks, and nixpkgs all at once
[group("system")]
update:
    #!/usr/bin/bash
    sudo /usr/bin/update all

# Turn automatic updates on or off
[group("system")]
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled catcat-os-update.timer | grep -q enabled; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic updates?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ujust toggle-updates <option>"
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
    ujust toggle-updates

# Toggle SSH
[group("network")]
toggle-ssh ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    # Get hostname and IP address
    HOSTNAME=$(hostname)
    IP_ADDRESS=$(hostname -I | awk '{print $1}') # First IP address
    # Get current SSH status
    SSH_STATUS_RUNNING=$(systemctl is-active sshd)
    SSH_STATUS="Disabled And ${SSH_STATUS_RUNNING[@]^}"
    if systemctl is-enabled sshd | grep -q enabled; then
      SSH_STATUS="Enabled And ${SSH_STATUS_RUNNING[@]^}"
    fi
    OPTION="{{ ACTION }}"
    if [ "${OPTION}" == "help" ]; then
      echo "Usage: ujust toggle-ssh <option>"
      echo "  <option>: Specify the option to skip the interactive prompt"
      echo "  Use 'start' to enable SSH till next reboot"
      echo "  Use 'persist-enable' to enable SSH persistently on boot"
      echo "  Use 'disable' to disable SSH"
      exit 0
    elif [ "${OPTION}" == "" ]; then
      # Display current status
      echo -e "\n${bold}Hostname:${normal} ${HOSTNAME}"
      echo -e "${bold}IP Address:${normal} ${IP_ADDRESS}"
      if [ "${SSH_STATUS}" == "Enabled" ]; then
        echo -e "${bold}SSH Status:${normal} ${green}${SSH_STATUS}${normal}\n"
      else
        echo -e "${bold}SSH Status:${normal} ${yellow}${SSH_STATUS}${normal}\n"
      fi
      # Prompt user for action
      echo "Choose an option:"
      OPTION=$(ugum choose "Start SSH Till Next Reboot" "Enable SSH Persistently" "Disable SSH" "Exit Without Saving")
    fi
    case "${OPTION}" in
      "Start SSH Till Next Reboot"|enable)
        echo "Starting SSH till next reboot..."
        sudo systemctl unmask sshd.service
        sudo systemctl start sshd.service
        echo -e "SSH is now ${green}Started${normal}. You can SSH using:"
        echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
        echo " "
        ;;
      "Disable SSH"|disable)
        echo "Disabling SSH on boot..."
        sudo systemctl disable sshd
        sudo systemctl stop sshd
        sudo systemctl mask sshd.service
        echo -e "SSH is now ${yellow}Disabled${normal}."
        echo " "
        ;;
      "Enable SSH Persistently"|persist-enable)
        echo "Enabling SSH on boot..."
        sudo systemctl unmask sshd.service
        sudo systemctl enable sshd
        sudo systemctl start sshd
        echo -e "SSH is now ${green}Enabled${normal}. You can SSH using:"
        echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
        echo " "
        ;;
      *)
        echo "No changes made."
        ;;
    esac

# Turn automatic nightly reboot on or off
[group("nightly reboot")]
toggle-nightly-reboot ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled catcat-nightly-reboot.timer | grep -q enabled; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic Nightly Reboot are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable Automatic Nightly Reboot?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ujust toggle-nightly-reboot <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable Automatic Nightly Reboot."
      echo "  Use 'disable' to Disable Automatic Nightly Reboot."
      exit 0
    fi
    if [[ "${OPTION,,}" == "enable" ]]; then
      sudo systemctl enable --force --now catcat-nightly-reboot.timer
    elif [[ "${OPTION,,}" == "disable" ]]; then
      sudo systemctl disable --force --now catcat-nightly-reboot.timer
    fi

# Cancel automatic nightly reboot sequence
[group("nightly reboot")]
cancel_nightly_reboot:
    #!/usr/bin/bash
    if [[ ! -d /tmp/CATCAT_NIGHTLY_REBOOT ]]; then
        echo "Nightly reboot was not sequenced correctly"
        exit 1
    fi
    echo "${USER}" | tee /tmp/CATCAT_NIGHTLY_REBOOT/user
    touch /tmp/CATCAT_NIGHTLY_REBOOT/cancelled_by_user_"${USER}"

# Enable or Disable Gnome Extension
[group("gnome desktop environment")]
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}

# Restore Gnome Desktop Environment settings
[group("gnome desktop environment")]
restore-gnome-de-settings:
    #!/usr/bin/bash
    source /usr/lib/catcat/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome settings..."
    dconf reset -f /
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Restore applications grid folders
[group("gnome desktop environment")]
restore-gnome-folders:
    #!/usr/bin/bash
    source /usr/lib/catcat/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome folders..."
    dconf reset -f /org/gnome/desktop/app-folders/
    dconf reset -f /org/gnome/shell/
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Revert any Gnome restoration made using "ujust restore-gnome-*"
[group("gnome desktop environment")]
revert-gnome-restoration:
    #!/usr/bin/bash
    if [[ -d "${HOME}/.config/dconf.bak" ]]; then
        echo "Reverting gnome settings..."
        mv "${HOME}/.config/dconf" "${HOME}/.config/dconf.before.revert"
        cp -drf "${HOME}/.config/dconf.bak" "${HOME}/.config/dconf"
        echo "Done."
        echo "You may need to log out and log in again for the changes to take effect."
    else
        echo "It is possible gnome settings backup was failed during previous restoration."
        echo "Or restoration was never performed."
    fi
