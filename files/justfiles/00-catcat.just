# Start SSH
[group("network")]
start-ssh:
    #!/usr/bin/bash
    sudo systemctl unmask sshd.service ; sudo systemctl start sshd

# Stop SSH
[group("network")]
stop-ssh:
    #!/usr/bin/bash
    sudo systemctl stop sshd ; sudo systemctl mask sshd.service

# Log all the errors
log-errors:
    #!/usr/bin/bash
    sudo journalctl -p err

# Log all the errors
log-selinux:
    #!/usr/bin/bash
    sudo sestatus
    echo ""
    sudo journalctl -t setroubleshoot

# Analyze system boot time
system-boot-time:
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

# Enable or Disable gnome extension
toggle-gnome-extension EXTENSION_ID:
    #!/usr/bin/bash
    EXTENSION_ID={{ EXTENSION_ID }}
    gnome-extensions $(gnome-extensions show ${EXTENSION_ID} | grep -qow 'ACTIVE' && echo "disable" || echo "enable") ${EXTENSION_ID}
