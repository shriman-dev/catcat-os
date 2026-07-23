# Enable automatic LUKS unlock via TPM
[group("disk management")]
setup-luks-tpm-unlock:
    #!/usr/bin/bash
    sudo /usr/libexec/luks-enable-tpm2-autounlock

# Disable automatic LUKS unlock via TPM
[group("disk management")]
remove-luks-tpm-unlock:
    #!/usr/bin/bash
    sudo /usr/libexec/luks-disable-tpm2-autounlock

# Refresh crypttab
[group("disk management")]
refresh-crypttab:
    #!/usr/bin/bash
    sudo systemctl daemon-reload
    sudo systemctl restart cryptsetup.target
    sudo systemctl daemon-reload

# Refresh fstab
[group("disk management")]
refresh-fstab:
    #!/usr/bin/bash
    sudo systemctl daemon-reload
    sudo mount --all
    sudo systemctl daemon-reload

# Create partition table
[group("disk management")]
create-partition-table TABLE_TYPE DEVICE_PATH:
    #!/usr/bin/bash
    sudo parted {{ DEVICE_PATH }} mktable {{ TABLE_TYPE }}

# Create luks partition
[group("disk management")]
create-luks-part DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup luksFormat --type luks2 --sector-size 4096 {{ DEVICE_PATH }}

# Dump info of luks device
[group("disk management")]
dump-info-luks DEVICE_PATH:
    #!/usr/bin/env -S sudo -- /bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    LUKS_UUID="luks-$(lsblk -lo UUID,FSTYPE {{ DEVICE_PATH }} | awk '/crypto_LUKS/ {print $1; exit}')"
    symmetric_heading "Luks Device Status"
    cryptsetup status "${LUKS_UUID}"
    echo ""
    symmetric_heading "Luks Device Info"
    cryptsetup luksDump {{ DEVICE_PATH }}

# Enable luks discard for better health of ssd
[group("disk management")]
enable-luks-discard LUKS_UUID:
    #!/usr/bin/env -S sudo -- /bin/bash
    echo 'Note: Add "discard" option for the device entry in /etc/crypttab'
    if [[ $(rpm-ostree kargs) =~ "luks.options=discard" ]]; then
        rpm-ostree kargs --append-if-missing=rd.luks.options=discard \
                         --append-if-missing=luks.options=discard
    fi
    cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue \
               --persistent refresh {{ LUKS_UUID }}
    if ! grep -q "^issue_discards = 1" /etc/lvm/lvm.conf; then
        sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf
        echo -e 'To enable discard regenerate initramfs using:\nsudo rpm-ostree initramfs --enable'
    fi

# Reencrypt luks device with sector size 4096 for some performance gain (Caution: backup data before proceeding)
[group("disk management")]
reencrypt-4096 DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup reencrypt --sector-size=4096 {{ DEVICE_PATH }}

# Add keyfile to luks device
[group("disk management")]
add-keyfile-luks DEVICE_PATH KEY_FILE ITER_VALUE:
    #!/usr/bin/env -S sudo -- /bin/bash
    if [[ ! -f {{ KEY_FILE }} ]]; then
        echo "Keyfile not found: {{ KEY_FILE }}"
        echo "Creating keyfile: {{ KEY_FILE }}"
        mkdir -p $(dirname {{ KEY_FILE }})
        dd if=/dev/urandom of={{ KEY_FILE }} bs=1024 count=4 &&
        chmod 0400 {{ KEY_FILE }} &&
        echo "Done."
    fi
    chmod 0400 {{ KEY_FILE }}
    cryptsetup luksAddKey {{ DEVICE_PATH }} {{ KEY_FILE }} --pbkdf-force-iterations {{ ITER_VALUE }}

# Delete luks keyslot
[group("disk management")]
delete-luks-keyslot DEVICE_PATH SLOT:
    #!/usr/bin/bash
    sudo cryptsetup luksKillSlot {{ DEVICE_PATH }} {{ SLOT }}

# Backup luks header
[group("disk management")]
backup-luks-header DEVICE_PATH BACKUP_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderBackup {{ DEVICE_PATH }} --header-backup-file {{ BACKUP_FILE }}

# Restore luks header
[group("disk management")]
restore-luks-header DEVICE_PATH HEADER_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderRestore {{ DEVICE_PATH }} --header-backup-file {{ HEADER_FILE }}
