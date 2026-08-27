#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

#############################
# Boot, Services and System #
#############################
log "INFO" "Checking dracut blacklist"
check_file_inplace /usr/lib/dracut/dracut.conf.d/99-omit-firewire-thunderbolt.conf

log "INFO" "Checking modprobe blacklist"
check_file_inplace /usr/lib/modprobe.d/secureblue.conf
check_file_inplace /usr/lib/modprobe.d/secureblue-framebuffer.conf

log "INFO" "Checking sysctl configuration"
check_file_inplace /usr/lib/sysctl.d/99-catcat-sysctl.conf

log "INFO" "Stop unneeded daemons dynamically"
systemd_dir="/usr/lib/systemd"
# Avahi daemon to stop when unneeded
mkdir -vp "${systemd_dir}/system"/avahi-daemon.{service.d,socket.d}
echo "[Unit]
StopWhenUnneeded=true" | tee \
            "${systemd_dir}/system"/avahi-daemon.{service.d,socket.d}/stop-when-unneeded.conf

log "INFO" "Disabling coredump for better security and performance"
no_coredump_conf="disable-coredump.conf"
mkdir -vp "${systemd_dir}"/{system,user}.conf.d
#echo 'ulimit -S -c 0' >> /etc/profile
echo "# Disable coredump
fs.suid_dumpable=0
kernel.core_pattern=|/bin/false" > "/etc/sysctl.d/99-${no_coredump_conf}"

echo "# Disable coredump
* hard core 0
* soft core 0" > "/etc/security/limits.d/${no_coredump_conf}"

echo "[Manager]
DumpCore=no" | tee "${systemd_dir}"/{system,user}.conf.d/"${no_coredump_conf}"

sed -i -Ee "/#?Storage=/d;/\[Coredump\]/a Storage=none" \
        -e "/#?ProcessSizeMax=/d;/\[Coredump\]/a ProcessSizeMax=0" \
        -e "/#?ExternalSizeMax=/d;/\[Coredump\]/a ExternalSizeMax=0" \
            "${systemd_dir}/coredump.conf"

log "INFO" "All Done."

# Configure Chrony
##################
log "INFO" "Configuring chrony NTP servers"
# Update chronyd
echo 'OPTIONS="-F1 -r"' > /etc/sysconfig/chronyd # for x86_64
#echo 'OPTIONS="-F2 -r"' > /etc/sysconfig/chronyd # for aarch

# 30 days retention period for files in directory: /var/lib/chrony
echo "d /var/lib/chrony 0755 chrony chrony 30d" > /etc/tmpfiles.d/chrony.conf

log "INFO" "Chrony Configuration done."


###########
# Network #
###########
log "INFO" "Checking MAC randomization and dynamic IPv6 address generation"
#ethernet.cloned-mac-address=random
networkmanager_confd="/usr/lib/NetworkManager/conf.d"
check_file_inplace "${networkmanager_confd}/mac-randomization.conf" \
                   "${networkmanager_confd}/privacy_ext_ipv6.conf"

# Harden SSH
log "INFO" "Checking harden SSH configuration"
check_file_inplace "/etc/ssh/sshd_config.d/catcat-ssh.conf"

# Ad/Malware blocking
log "INFO" "Adding support for Ad/Malware blocking"
# Install dnscrypt-proxy if not installed
#####

# Enable localdns
log "INFO" "Enabling localdns"
check_file_inplace "/etc/${PROJECT_NAME}/localdns.d/config.json"

TMP_DIR="${BUILD_CACHE_DIR}/fetched" \
bash -x /usr/bin/localdnsctl -v --switch-backend dnscrypt --setup

# Remove symlinked resolv conf in post setup
[[ -L /etc/resolv.conf ]] && log "WARN" "/etc/resolv.conf is a symlink, remove it in post setup"
log "INFO" "Network setup done."

######################################################
# File Permissions, Users, Groups and Authentication #
######################################################
# Set right perms to sudoers.d
log "INFO" "Setting right permissions to sudoers.d"
sudoers_dir="/etc/sudoers.d"
chmod -v --recursive 440 "${sudoers_dir}"
chmod -v 440 "${sudoers_dir}"

# Harden login.defs with file creation perms set to 640 via umask 027 and increased cost of hashing
log "INFO" "Improving settings in login.defs"
login_defs="/etc/login.defs"
faillock_conf="/etc/security/faillock.conf"
pwquality_conf="/etc/security/pwquality.conf"
sed -i -Ee 's/^(UMASK[[:space:]]+).*/\1027/' \
        -e 's/.*(YESCRYPT_COST_FACTOR[[:space:]]+).*/\18/' "${login_defs}"

# Password fail lock
log "INFO" "Enabling password fail lock"
sed -i -Ee 's|^(#?[[:space:]]*audit)|audit|' \
        -e 's|^(#?[[:space:]]*deny =.*)|deny = 5|' \
        -e 's|^(#?[[:space:]]*unlock_time =.*)|unlock_time = 86400|' \
        -e 's|^(#?[[:space:]]*even_deny_root)|even_deny_root|' "${faillock_conf}"

# Password quality check
log "INFO" "Improving password quality check"
sed -i -Ee 's|^(#?[[:space:]]*minlen =.*)|minlen = 12|' \
        -e 's|^(#?[[:space:]]*dictcheck =.*)|dictcheck = 1|' \
        -e 's|^(#?[[:space:]]*usercheck =.*)|usercheck = 1|' \
        -e 's|^(#?[[:space:]]*usersubstr =.*)|usersubstr = 5|' \
        -e 's|^(#?[[:space:]]*enforcing =.*)|enforcing = 0|' "${pwquality_conf}"

# After User Login
###############
log "INFO" "Checking autostart desktop file that mutes mic on user login"
mute_mic_file="/etc/xdg/autostart/mute-mic.desktop"
check_file_inplace "${mute_mic_file}"

######################
# Package Management #
######################
log "INFO" "Setting all RPM repos to use HTTPS protocol"
for dnf_repo in /etc/yum.repos.d/*.repo; do
    sed -i 's/metalink?/metalink?protocol=https\&/g' "${dnf_repo}"
done
