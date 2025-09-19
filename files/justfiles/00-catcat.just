# Start SSH
[group("network")]
start-ssh:
    #!/usr/bin/bash
    sudo systemctl unmask sshd.service ; sudo systemctl start sshd

# Stop SSH
[group("network")]
stop-ssh:
    #!/usr/bin/bash
    sudo systemctl mask sshd.service ; sudo systemctl stop sshd

# Log all the errors
log-errors:
    #!/usr/bin/bash
    sudo journalctl -p err

# Log all the errors
log-selinux:
    #!/usr/bin/bash
    sudo journalctl -t setroubleshoot

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
    sudo fpaste --sysinfo --printonly
    echo -e "\n===System flatpaks history===\n"
    sudo flatpak --system history
    echo -e "\n===User flatpaks history===\n"
    flatpak --user history
    echo -e "\n=== Recent System Events ===\n"
    sudo journalctl -b -p err..alert --since "1 day ago"
    echo -e "\n=== Sys+Hardware Information ===\n"
    sudo inxi --basic --expanded -xxxa --verbosity 8
    echo -e "\n=== Listing Local Overrides ===\n"
    sudo ujust check-local-overrides
    echo -e "\n=== Failed Services ===\n"
    sudo systemctl list-units --state=failed
    echo -e "\n=== Rpm-Ostree Status ===\n"
    sudo rpm-ostree status --verbose
    echo -e "\n=== CatCat OS Changelog ===\n"
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

# Turn automatic nightly reboot on or off
toggle-nightly-reboot:
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


# Enable or Disable gnome extension
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}
