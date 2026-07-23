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
[group("utilities")]
enroll-secure-boot-key:
    #!/usr/bin/bash
    /usr/bin/enroll-sbmok


# Automatically manage power profiles
[group("utilities")]
toggle-auto-power-profile ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled --quiet auto-power-profile.service; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [[ "${OPTION}" == "prompt" ]]; then
      echo "Automatic power profile management status: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic power profile management?"
      OPTION=$(ugum choose Enable Disable)
    elif [[ "${OPTION,,}" == "help" ]]; then
      echo "Usage: ucat toggle-auto-power-profile <option>"
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

