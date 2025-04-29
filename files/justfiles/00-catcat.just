# Check for local overrides
check-local-overrides:
    #!/usr/bin/bash
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
    echo -e "=== Rpm-Ostree Status ===\n"
    sudo rpm-ostree status --verbose
    echo -e "\n"
    sudo fpaste --sysinfo --printonly
    echo "=== Flatpaks Installed ==="
    flatpak list --columns=name,application,version,size,origin,options
    echo -e "\n=== Listing Local Overrides ===\n"
    sudo ostree admin config-diff && ujust check-local-overrides
    echo -e "\n=== Recent System Events ===\n"
    sudo journalctl -b -p err..alert --since "1 day ago"
    echo -e "\n=== Failed Services ===\n"
    sudo systemctl list-units --state=failed
    echo -e "\n=== CatCat OS Changelog ===\n"
    sudo rpm-ostree db diff --changelogs
    echo -e "\n---System flatpaks changelog---\n"
    sudo flatpak --system history
    echo -e "\n---User flatpaks changelog---\n"
    flatpak --user history

# Update system, flatpaks, and nixpkgs all at once
update:
    #!/usr/bin/bash
    /usr/bin/update all

# Turn automatic updates on or off
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled catcat-os-update.timer | grep -q enabled; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "prompt" ]; then
      echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic updates?"
      OPTION=$(ugum choose Enable Disable)
    elif [ "$OPTION" == "help" ]; then
      echo "Usage: ujust toggle-updates <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable automatic updates."
      echo "  Use 'disable' to Disable automatic updates."
      exit 0
    fi
    if [ "${OPTION,,}" == "enable" ]; then
      sudo systemctl enable catcat-os-update.timer
    elif [ "${OPTION,,}" == "disable" ]; then
      sudo systemctl disable catcat-os-update.timer
    fi

# Enable or Disable gnome extension
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/env bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}
