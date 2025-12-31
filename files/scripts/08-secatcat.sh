#!/bin/bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

#############################
# Boot, Services and System #
#############################
log "INFO" "Configuring unneeded daemons to stop"
systemd_dir="/usr/lib/systemd"
# Avahi daemon to stop when unneeded
mkdir -vp ${systemd_dir}/system/avahi-daemon.{service.d,socket.d}
echo "[Unit]
StopWhenUnneeded=true" | tee ${systemd_dir}/system/avahi-daemon.{service.d,socket.d}/stop-when-unneeded.conf

# Disable coredump for better security and performance
log "INFO" "Disabling coredump for better security and performance"
no_coredump_conf="disable-coredump.conf"
mkdir -vp ${systemd_dir}/{system,user}.conf.d
#echo 'ulimit -S -c 0' >> /etc/profile
echo "# Disable coredump
fs.suid_dumpable=0
kernel.core_pattern=|/bin/false" > "/etc/sysctl.d/99-${no_coredump_conf}"

echo "# Disable coredump
* hard core 0
* soft core 0" > "/etc/security/limits.d/${no_coredump_conf}"

echo "[Manager]
DumpCore=no" | tee ${systemd_dir}/{system,user}.conf.d/${no_coredump_conf}

sed -i -Ee "/#?Storage=/d;/\[Coredump\]/a Storage=none" \
        -e "/#?ProcessSizeMax=/d;/\[Coredump\]/a ProcessSizeMax=0" \
        -e "/#?ExternalSizeMax=/d;/\[Coredump\]/a ExternalSizeMax=0" \
            "${systemd_dir}/coredump.conf"

log "INFO" "All Done."

# Configure Chrony
##################
log "INFO" "Configuring chrony NTP servers"
tmp_chrony="/tmp/chrony_conf"
chrony_conf="/etc/chrony.conf"
grapheneos_repo="https://raw.githubusercontent.com/GrapheneOS/infrastructure/refs/heads/main"

mkdir -vp "${tmp_chrony}"
curl -Lo "${tmp_chrony}/LICENSE" "${grapheneos_repo}/LICENSE"
curl -Lo "${tmp_chrony}/chrony.conf" "${grapheneos_repo}${chrony_conf}"

sed 's/^/# /' "${tmp_chrony}/LICENSE" > "${tmp_chrony}/LICENSE_temp"
cat "${tmp_chrony}/LICENSE_temp" > "${chrony_conf}"
cat "${tmp_chrony}/chrony.conf" >> "${chrony_conf}"
# Update chronyd
sed -i 's/^OPTIONS=.*$/OPTIONS="-F 1 -r"/' /etc/sysconfig/chronyd

# 30 days retention period for files in directory: /var/lib/chrony
echo "d /var/lib/chrony 0755 chrony chrony 30d" > /etc/tmpfiles.d/chrony.conf

# Clear tmp
rm -rvf "${tmp_chrony}"

log "INFO" "Chrony Configuration done."


###########
# Network #
###########
log "INFO" "Setting up network for image: ${IMAGE_NAME}"
# Enable MAC randomization and temporary IPv6 addresses generation
log "INFO" "Enabling MAC randomization and dynamic IPv6 address generation"
networkmanager_confd="/usr/lib/NetworkManager/conf.d"
#ethernet.cloned-mac-address=random
cat > "${networkmanager_confd}/mac-randomization.conf" << EOF
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
EOF

cat > "${networkmanager_confd}/privacy_ext_ipv6.conf" << EOF
[connection]
ipv6.ip6-privacy=2
EOF

# Ad/Malware blocking
log "INFO" "Adding support for Ad/Malware blocking"
# Install dnscrypt-proxy
tmp_localdns="/tmp/localdns.d"
localdns_confd="/etc/catcat-os/localdns.d"
dnscrypt_resolver_repo="https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/refs/heads/master"
dnscrypt_repo="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy"
dnscrypt_tar="${tmp_localdns}/dnscrypt-proxy.tar.gz"
dnscrypt_confd="/etc/dnscrypt-proxy"
ushare_localdns="/usr/share/localdns.d"
dns_blocklist_repo="https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main"

log "INFO" "Installing dnscrypt-proxy"
mkdir -vp "${dnscrypt_tar}.extract"
curl -Lo "${dnscrypt_tar}" \
        $(curl -s -X GET "${dnscrypt_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux_x86_64-.*.tar.gz"' | cut -d '"' -f4)

tar -xvf "${dnscrypt_tar}" -C "${dnscrypt_tar}.extract"
cp -dvf "${dnscrypt_tar}.extract/linux-x86_64/dnscrypt-proxy" "/usr/bin/"
chmod -v +x "/usr/bin/dnscrypt-proxy"

curl -Lo "${dnscrypt_confd}/public-resolvers.md" "${dnscrypt_resolver_repo}/v3/public-resolvers.md"
curl -Lo "${dnscrypt_confd}/public-resolvers.md.minisig" \
                "${dnscrypt_resolver_repo}/v3/public-resolvers.md.minisig"

rm -rf "${dnscrypt_tar}" "${dnscrypt_tar}.extract"
log "INFO" "Done."

# Get DNS blocklist archive
log "INFO" "Get DNS Ad and Malware blocklist"
mkdir -vp "${ushare_localdns}"/{dnscrypt,dnsmasq}

# Dnscrypt blocklist
[[ -f "${localdns_confd}/only-dnscrypt-blocklist" ]] && {
    curl -Lo "${tmp_localdns}/domains-filtered-subdomains.tar.zst" \
                "${dns_blocklist_repo}/domains.d/domains-filtered-subdomains.tar.zst"
    split -dC 5M "${tmp_localdns}/domains-filtered-subdomains.tar.zst" \
                "${ushare_localdns}/dnscrypt/domains-filtered-subdomains.tar.zst"
}

# Dnsmasq blocklist
[[ ! -f "${localdns_confd}/only-dnscrypt-blocklist" ]] && {
    log "INFO" "Make DNSMasq to read conf files from: /etc/dnsmasq.d"
    echo 'conf-dir=/etc/dnsmasq.d/,*.conf' >> /etc/dnsmasq.conf
    curl -Lo "${tmp_localdns}/blocklist.conf.tar.zst" \
                "${dns_blocklist_repo}/dnsmasq.d/blocklist.conf.tar.zst"
    split -dC 5M "${tmp_localdns}/blocklist.conf.tar.zst" \
                "${ushare_localdns}/dnsmasq/blocklist.conf.tar.zst"
}

log "INFO" "Enabling localdns"
# Set localdns as default dns server for blocking ads/malwares
cp -vf "${localdns_confd}/localdns-server.conf" /etc/NetworkManager/conf.d/

# Disable and mask systemd-resolved.service
systemctl disable systemd-resolved.service
systemctl mask systemd-resolved.service

# Enable blocklist updater
systemctl -f enable dns-blocklist-updater.timer

if [[ "${IMAGE_NAME}" =~ "-mi" ]]; then
    /usr/bin/localdnsctl -v --switch-blocklist-backend dnsmasq
    systemctl -f enable dnsmasq.service
else
    /usr/bin/localdnsctl -v --switch-blocklist-backend dnscrypt
    systemctl -f enable dnscrypt-proxy.service
fi

# Clear tmp
rm -rvf "${tmp_localdns}"
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
# Create a xdg autostart file to mute microphone at login
log "INFO" "Adding autostart desktop file that mutes mic on user login"
mute_mic_file="/etc/xdg/autostart/mute-mic.desktop"
mkdir -pv "$(dirname ${mute_mic_file})"
cat > "${mute_mic_file}" << EOF
[Desktop Entry]
Hidden=false
Name=Mute Microphone on Login
Comment=Mute Microphone on Login
Terminal=false
Exec=/usr/bin/amixer set Capture nocap
Type=Application
EOF
chmod -v 644 "${mute_mic_file}"

######################
# Package Management #
######################
# Make all repos to use https protocol
log "INFO" "Setting all RPM repos to use HTTPS protocol"
for repo in /etc/yum.repos.d/*.repo; do
    sed -i 's/metalink?/metalink?protocol=https\&/g' "${repo}"
done
