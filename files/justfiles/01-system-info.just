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
    sudo ucat log-selinux
    symmetric_heading "Listing Local Overrides" "="
    sudo ucat check-local-overrides
    symmetric_heading "Failed Services" "="
    sudo systemctl list-units --state=failed
    symmetric_heading "Last 50 Logins, Reboots and Shutdowns" "="
    last -x -n50
    symmetric_heading "Rpm-Ostree Status" "="
    sudo rpm-ostree status --verbose
    symmetric_heading "CatCat OS Changelog" "="
    sudo rpm-ostree db diff --changelogs

