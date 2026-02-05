# Boot into this device's BIOS/UEFI screen
[group("utilities")]
bios:
    #!/usr/bin/bash
    if [[ -d /sys/firmware/efi ]]; then
      systemctl reboot --firmware-setup
    else
      echo "Rebooting to legacy BIOS from OS is not supported."
    fi


# Enroll signing key for secure boot - Enter password "catcat" when prompted
enroll-secure-boot-key:
    #!/usr/bin/bash
    /usr/bin/enroll-sbmok


# Automatically manage power profiles
[group("utilities")]
toggle-auto-power-profile ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled auto-power-profile.service | grep -q enabled; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic power profile management status: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic power profile management?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ujust toggle-auto-power-profile <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable automatic power profile management."
      echo "  Use 'disable' to Disable automatic power profile management."
      exit 0
    fi
    if [[ "${OPTION,,}" == "enable" ]]; then
      sudo systemctl enable --force --now auto-power-profile.service
    elif [[ "${OPTION,,}" == "disable" ]]; then
      sudo systemctl disable --force --now auto-power-profile.service
    fi

# Measure Idle Power Draw
[group("utilities")]
check-idle-power-draw:
    #!/usr/bin/bash
    sudo powerstat -a -r

# Clean up unused, unnecessary stuff and optimize podman, flatpaks, brew, nix and rpm-ostree content
[group("utilities")]
clean-system:
    #!/usr/bin/bash
    [[ $(id -u) -eq 0 ]] && systemd-tmpfiles --clean
    podman image prune -af
    podman volume prune -f
    flatpak uninstall --unused --assumeyes --noninteractive
    rpm-ostree cleanup -bm
    if command -v nix-store >/dev/null 2>&1; then
        nix-store --optimise
        nix-collect-garbage
    fi
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew autoremove
        brew cleanup
    fi

# Add user to "input" group required by certain controller drivers
[group("utilities")]
add-user-to-input-group:
    #!/usr/bin/bash
    if ! grep -q "input" /etc/group; then
      sudo bash -c 'grep "input" /lib/group >> /etc/group'
    fi
    sudo usermod -a -G input ${USER}

# Install default and extra flatpak apps
[group("apps")]
install-catcat-flatpaks:
    #!/usr/bin/bash
    sudo /usr/libexec/catcat-flatpak-manager --install-all

# Install app for controlling fans on msi laptops
[group("apps")]
install-mcontrolcenter:
    #!/usr/bin/env -S sudo -- /bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    log "INFO" "Installing mcontrolcenter"
    TMP_DIR="/tmp/extra_pkgs"
    pkg_name="mcontrolcenter"
    latest_pkg_url="$(latest_ghpkg_url 'dmitry-s93/MControlCenter' 'bin\.tar\.gz$')"
    pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl_get "${pkg_archive}" "${latest_pkg_url}"
    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    auto_fold_dir=($(populated_or_afile_dirs "${pkg_archive}.extract"))

    sed -i "s|/usr/|/usr/local/|" "${auto_fold_dir[0]}"/install.sh
    sed -i "s|/usr/|/usr/local/|" "${auto_fold_dir[0]}"/app/mcontrolcenter.helper.service
    cd "${auto_fold_dir[0]}"
    "${auto_fold_dir[0]}"/install.sh
    ln -svf /usr/local/share/applications/mcontrolcenter.desktop \
                ${SUDO_USER}/.config/autostart/mcontrolcenter.desktop
    cd -
    rm -rf "${TMP_DIR}"
    log "INFO" "All Done."

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
    sudo journalctl --no-hostname --merge --priority=3..0

# Show selinux related logs
[group("logging")]
logs-selinux:
    #!/usr/bin/bash
    sudo sestatus
    echo " "
    sudo journalctl --no-hostname -t setroubleshoot

# Show warnings, errors and critical kernel/dmesg logs
[group("logging")]
logs-dmesg:
    #!/usr/bin/bash
    sudo dmesg --color=auto --decode --human --level warn,err,crit,alert,emerg

# SHow all the logs
[group("logging")]
get-logs:
    #!/usr/bin/bash
    sudo journalctl --no-hostname --merge

# Show BIOS info
[group("system info")]
bios-info:
    #!/usr/bin/bash
    echo "Manufacturer: $(sudo dmidecode -s baseboard-manufacturer)"
    echo "Product Name: $(sudo dmidecode -s baseboard-product-name)"
    echo "Version: $(sudo dmidecode -s bios-version)"

# Analyze system boot time
[group("system info")]
boot-time-analyze:
    #!/usr/bin/bash
    systemd-analyze critical-chain
    echo " "
    systemd-analyze time

# Show the changelog
[group("system info")]
changelogs:
    rpm-ostree db diff --changelogs

# Check for local overrides
[group("system info")]
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
             --exclude="public-resolvers.md*" \
             --exclude="relays.md*" \
             --exclude="domains-blocklist.*" \
             /usr/etc /etc 2>/dev/null | sed '/Binary\ files\ /d' | \
                rg --color=always --colors 'match:fg:yellow' --passthru 'Only in.*'


# Get device info
[group("system info")]
device-info:
    #!/usr/bin/bash
    sudo fastfetch
    symmetric_heading "Detailed Sys+Hardware Information" "="
    sudo inxi --basic --expanded -xxxa --verbosity 8

# Dump debug info
[group("system info")]
debug-info:
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
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

# Automatic updates only on specific connection. Connection types: ethernet or wifi. For specific Wi-Fi network use 'wifi=<SSID>'
[group("system")]
auto-update-on-connection CONNECTION:
    #!/usr/bin/env -S sudo -- /bin/bash
    CONNECTION={{ CONNECTION }}
    mkdir -p /etc/catcat-os/
    echo "${CONNECTION}" > /etc/catcat-os/auto_update_on_connection


# Turn automatic updates on or off
_toggle-updates:
    #!/usr/bin/bash
    ujust toggle-updates

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
    if systemctl is-enabled sshd | grep -q enabled; then
      SSH_STATUS="Enabled And ${SSH_STATUS_RUNNING[@]^}"
    fi
    OPTION="{{ ACTION }}"
    if [[ "${OPTION}" == "help" ]]; then
      echo "Usage: ujust toggle-ssh <option>"
      echo "  <option>: Specify the option to skip the interactive prompt"
      echo "  Use 'start' to start SSH till next reboot"
      echo "  Use 'enable' to enable SSH persistently on boot"
      echo "  Use 'disable' to disable SSH"
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
      OPTION=$(ugum choose "Start SSH Till Next Reboot" "Enable SSH Persistently" "Disable SSH" "Exit Without Saving")
    fi
    case "${OPTION}" in
      "Start SSH Till Next Reboot"|start)
        echo "Starting SSH till next reboot..."
        sudo systemctl unmask sshd.service sshd.socket sshd-unix-local.socket
        sudo systemctl start  sshd.service sshd-unix-local.socket
        echo -e "SSH is now ${green}Started${normal}. You can SSH using:"
        echo -e "${bold}${USER}@${IP_ADDRESS}${normal}"
        echo " "
        ;;
      "Disable SSH"|disable)
        echo "Disabling SSH on boot..."
        sudo systemctl disable sshd.service sshd-unix-local.socket
        sudo systemctl stop sshd.service sshd-unix-local.socket
        sudo systemctl mask sshd.service sshd.socket sshd-unix-local.socket
        echo -e "SSH is now ${yellow}Disabled${normal}."
        echo " "
        ;;
      "Enable SSH Persistently"|enable)
        echo "Enabling SSH on boot..."
        sudo systemctl unmask sshd.service sshd.socket sshd-unix-local.socket
        sudo systemctl enable sshd.service
        sudo systemctl start  sshd.service sshd-unix-local.socket
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
    source /usr/lib/catcat-os/funcvar.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled nightly-reboot.timer | grep -q enabled; then
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

# Enable or Disable Gnome Extension
[group("gnome desktop")]
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}

# Restore Gnome DE settings
[group("gnome desktop")]
restore-gnome-de-settings:
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome settings..."
    rm -rf "${HOME}/.config/dconf"
    dconf reset -f /
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Restore applications grid folders
[group("gnome desktop")]
restore-gnome-folders:
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    VERBOSE=
    bak_before "${HOME}/.config/dconf"
    echo "Restoring gnome folders..."
    dconf reset -f /org/gnome/desktop/app-folders/
    dconf reset /org/gnome/shell/app-picker-layout
    echo "Done."
    echo "You may need to log out and log in again for the changes to take effect."

# Revert any Gnome restoration made using "ujust restore-gnome-*"
[group("gnome desktop")]
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
