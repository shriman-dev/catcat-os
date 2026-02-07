#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Regenerating initramfs"
KERNEL_PATH=(
    $(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -exec test -e "{}/initramfs.img" \; -print)
)

DRACUT="/usr/bin/dracut"

# Use dracut cliwrap if already installed
[[ -f "/usr/libexec/rpm-ostree/wrapped/dracut" ]] &&
    DRACUT="/usr/libexec/rpm-ostree/wrapped/dracut"

# Set dracut log levels via temporary config file
# To prevent performance issues from default journal logging
temp_conf_file="$(mktemp '/etc/dracut.conf.d/zzz-loglevels-XXXXXXXXXX.conf')"
cat > "${temp_conf_file}" <<'EOF'
stdloglvl=4
sysloglvl=0
kmsgloglvl=0
fileloglvl=0
EOF

if [[ "${#KERNEL_PATH[@]}" -gt 1 ]]; then
    log "WARN" "Multiple kernel versions found"
    log "WARN" "Single kernel recommended for faster initramfs regeneration"
elif [[ "${#KERNEL_PATH[@]}" -eq 0 ]]; then
    die "Failed to find kernel"
fi

for kernel_path in "${KERNEL_PATH[@]}"; do
    kernel_ver="$(basename ${kernel_path})"
    initramfs_image="${kernel_path}/initramfs.img"
    log "INFO" "Starting initramfs regeneration for kernel version: ${kernel_ver}"
    ${DRACUT} --kver "${kernel_ver}" \
              --no-hostonly --reproducible --add ostree --force "${initramfs_image}"
    chmod -v 0600 "${initramfs_image}"
done

rm -vf -- "${temp_conf_file}"

log "INFO" "Initramfs regeneration completed"
