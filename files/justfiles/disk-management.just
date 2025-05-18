# Create partition table
create-partition-table TABLE_TYPE DEVICE_PATH:
    #!/usr/bin/bash
    sudo parted {{ DEVICE_PATH }} mktable {{ TABLE_TYPE }}

# Dump info of luks device
dump-info-luks DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup luksDump {{ DEVICE_PATH }}

# Reencrypt luks device with sector size 4096 for some performance gain (Caution: backup data before proceeding)
reencrypt-4096 DEVICE_PATH:
    #!/usr/bin/bash
    sudo cryptsetup reencrypt --sector-size=4096 {{ DEVICE_PATH }}

# Enable luks discard for better health of ssd
enable-luks-discard DEVICE_MAPPER_PATH:
    #!/usr/bin/bash
    echo 'Add "discard" option for the device entry in /etc/crypttab'
    sudo sed -i "s|.*issue_discards =.*|issue_discards = 1|"
    sudo rpm-ostree kargs --append-if-missing=rd.luks.options=discard --append-if-missing=luks.options=discard
    sudo cryptsetup refresh --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent {{ DEVICE_MAPPER_PATH }}
    echo -e 'Regenerate initramfs using:\nsudo rpm-ostree initramfs --enable'

# Add keyfile to luks device
add-keyfile-luks DEVICE_PATH KEY_FILE ITER_VALUE:
    #!/usr/bin/bash
    sudo cryptsetup luksAddKey {{ DEVICE_PATH }} {{ KEY_FILE }} --pbkdf-force-iterations {{ ITER_VALUE }}

# Delete luks keyslot
delete-luks-keyslot SLOT:
    #!/usr/bin/bash
    sudo cryptsetup luksKillSlot {{ SLOT }}

# Backup luks header
backup-luks-header DEVICE_PATH BACKUP_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderBackup {{ DEVICE_PATH }} --header-backup-file {{ BACKUP_FILE }}

# Restore luks header
restore-luks-header DEVICE_PATH HEADER_FILE:
    #!/usr/bin/bash
    sudo cryptsetup luksHeaderRestore {{ DEVICE_PATH }} --header-backup-file {{ HEADER_FILE }}
