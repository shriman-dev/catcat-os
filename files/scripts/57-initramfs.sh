#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Regenerating initramfs"

# Use dracut cliwrap if already installed
if [[ -f "/usr/libexec/rpm-ostree/wrapped/dracut" ]]; then
    DRACUT="/usr/libexec/rpm-ostree/wrapped/dracut"
else
    DRACUT="/usr/bin/dracut"
fi

KERNEL_MODULES_PATH="/usr/lib/modules"
#dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel
readarray -t QUALIFIED_KERNEL < <(find "${KERNEL_MODULES_PATH}" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

if [[ "${#QUALIFIED_KERNEL[@]}" -gt 1 ]]; then
    log "INFO" "NOTE: There are several versions of kernel's initramfs."
    log "INFO" "      It is most ideal to have only 1 kernel, to make initramfs regeneration faster."
fi

# Set dracut log levels via temporary config file
# To prevent performance issues from default journal logging
temp_conf_file="$(mktemp '/etc/dracut.conf.d/zzz-loglevels-XXXXXXXXXX.conf')"
cat > "${temp_conf_file}" <<'EOF'
stdloglvl=4
sysloglvl=0
kmsgloglvl=0
fileloglvl=0
EOF

for qual_kernel in "${QUALIFIED_KERNEL[@]}"; do
    INITRAMFS_IMAGE="${KERNEL_MODULES_PATH}/${qual_kernel}/initramfs.img"
    log "INFO" "Starting initramfs regeneration for kernel version: ${qual_kernel}"
    "${DRACUT}" --kver "${qual_kernel}" \
                --no-hostonly --reproducible --add ostree --force "${INITRAMFS_IMAGE}"
    chmod -v 0600 "${INITRAMFS_IMAGE}"
done

rm -vf -- "${temp_conf_file}"

log "INFO" "All done."
