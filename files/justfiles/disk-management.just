# Create partition table
[group("Disk Management")]
create-partition-table TABLE_TYPE DEVICE_PATH:
    #!/usr/bin/bash
    sudo parted {{ DEVICE_PATH }} mktable {{ TABLE_TYPE }}

# Create luks partition
[group("Disk Management")]
create-luks-part DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup luksFormat --type luks2 --sector-size 4096 {{ DEVICE_PATH }}

# Dump info of luks device
[group("Disk Management")]
dump-info-luks DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup luksDump {{ DEVICE_PATH }}

# Enable luks discard for better health of ssd
[group("Disk Management")]
enable-luks-discard DEVICE_NAME:
    #!/usr/bin/env -S sudo -- /bin/bash
    echo 'Note: Add "discard" option for the device entry in /etc/crypttab'
    if [[ $(rpm-ostree kargs) =~ "luks.options=discard" ]]; then
        rpm-ostree kargs --append-if-missing=rd.luks.options=discard \
                --append-if-missing=luks.options=discard
    fi
    cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue \
            --persistent refresh {{ DEVICE_NAME }}
    if ! grep -q "^issue_discards = 1" /etc/lvm/lvm.conf; then
        sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf
        echo -e 'To enable discard regenerate initramfs using:\nsudo rpm-ostree initramfs --enable'
    fi

# Reencrypt luks device with sector size 4096 for some performance gain (Caution: backup data before proceeding)
[group("Disk Management")]
reencrypt-4096 DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup reencrypt --sector-size=4096 {{ DEVICE_PATH }}

# Add keyfile to luks device
[group("Disk Management")]
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
[group("Disk Management")]
delete-luks-keyslot DEVICE_PATH SLOT:
    #!/usr/bin/bash
    sudo cryptsetup luksKillSlot {{ DEVICE_PATH }} {{ SLOT }}

# Backup luks header
[group("Disk Management")]
backup-luks-header DEVICE_PATH BACKUP_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderBackup {{ DEVICE_PATH }} --header-backup-file {{ BACKUP_FILE }}

# Restore luks header
[group("Disk Management")]
restore-luks-header DEVICE_PATH HEADER_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderRestore {{ DEVICE_PATH }} --header-backup-file {{ HEADER_FILE }}

# Auto unlock encrypted root
[group("Disk Management")]
auto-unlock-encrypted-root KEY_FILE DEVICE_PATH:
    #!/usr/bin/env -S sudo -- /bin/bash
    root_luks_uuid="$(basename $(findmnt -n -o SOURCE -T "/sysroot" | cut -d '[' -f 1))"
    echo "Presuming {{ KEY_FILE }} is correctly added as a keyfile for the LUKS root encryption"
    echo "If not, please add it using command: ujust add-keyfile-luks"
    if grep -qE "${root_luks_uuid}.*none" /etc/crypttab; then
        sed -i 's/none.*/{{ KEY_FILE }} luks,discard,no-read-workqueue,no-write-workqueue,keyfile-timeout=5s/' /etc/crypttab
        echo "install_items=\"{{ KEY_FILE }} /etc/crypttab\"" | tee /etc/dracut.conf.d/99-root-luks-key.conf
        rpm-ostree initramfs --disable ; rpm-ostree initramfs --enable
    else
        echo "Looks like a keyfile already set for LUKS root encryption"
        echo "Edit it manually using command: sudo $EDITOR /etc/crypttab"
        echo "Then run below command respectively"
        echo 'echo "install_items=\"{{ KEY_FILE }} /etc/crypttab\"" | sudo tee /etc/dracut.conf.d/99-root-luks-key.conf'
        echo "sudo rpm-ostree initramfs --disable ; sudo rpm-ostree initramfs --enable"
    fi
