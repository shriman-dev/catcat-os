# Check for local overrides
check-local-overrides:
    #!/usr/bin/bash
    diff -r \
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
toggle-extension EXTENSION_ID:
    #!/usr/bin/env bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}

