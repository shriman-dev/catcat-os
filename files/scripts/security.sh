#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

# Disable coredump
# Add a line to disable core dumps in limits.conf
echo "* hard core 0" | tee -a /etc/security/limits.conf
echo "* soft core 0" | tee -a /etc/security/limits.conf

echo "[Coredump]" | tee /etc/systemd/coredump.conf > /dev/null
echo "Storage=none" | tee -a /etc/systemd/coredump.conf > /dev/null
echo "ProcessSizeMax=0" | tee -a /etc/systemd/coredump.conf > /dev/null
echo "ExternalSizeMax=0" | tee -a /etc/systemd/coredump.conf > /dev/null

mkdir -p /etc/systemd/{system.conf.d,user.conf.d}
echo "[Manager]" | tee /etc/systemd/{system.conf.d,user.conf.d}/60-disable-coredump.conf > /dev/null
echo "DumpCore=no" | tee -a /etc/systemd/{system.conf.d,user.conf.d}/60-disable-coredump.conf > /dev/null

# Create a xdg autostart file to mute microphone on boot
cat > /etc/xdg/autostart/mute-mic.desktop << EOF
[Desktop Entry]
Type=Application
Name=Mute Microphone on Login
Exec=/usr/bin/amixer set Capture nocap
Icon=utilities-terminal
EOF

chmod 644 /etc/xdg/autostart/mute-mic.desktop

# Mac Randomization
cat > /etc/NetworkManager/conf.d/00-mac-randomization.conf << EOF
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

# Ad/Malware blocking with dnsmasq and dnscrypt-proxy
# install dnscrypt-proxy
curl -Lo /tmp/dnscrypt-proxy.tar.gz $(curl -s -X GET https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -i '"browser_download_url": "[^"]*linux_x86_64-.*.tar.gz"' | cut -d '"' -f4)
mkdir -p /tmp/dnscrypt-proxyTarExtract
tar -xf /tmp/dnscrypt-proxy.tar.gz -C /tmp/dnscrypt-proxyTarExtract
cp -dvf /tmp/dnscrypt-proxyTarExtract/linux-x86_64/dnscrypt-proxy /usr/bin/
chmod +x /usr/bin/dnscrypt-proxy

curl -Lo /etc/public-resolvers.md https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md
curl -Lo /etc/public-resolvers.md.minisig https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md.minisig


# enable dnsmasq and dnscrypt-proxy
sh -c "echo 'conf-dir=/etc/dnsmasq.d/,*.conf' >> /etc/dnsmasq.conf"
systemctl -f enable dnscrypt-proxy.service dnsmasq.service
systemctl disable systemd-resolved.service

# get dns blocklist archive
mkdir -p /usr/share/dnscrypt-proxy /usr/share/dnsmasq/dns-blocklist-archive

#curl -Lo /tmp/blocklist.conf.tar.zst https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/dnsmasq.d/blocklist.conf.tar.zst
#split -dC 5M /tmp/blocklist.conf.tar.zst /usr/share/dnsmasq/dns-blocklist-archive/blocklist.conf.tar.zst

curl -Lo /tmp/domains-filtered-subdomains.tar.zst https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/domains.d/domains-filtered-subdomains.tar.zst
split -dC 5M /tmp/domains-filtered-subdomains.tar.zst /usr/share/dnscrypt-proxy/domains-filtered-subdomains.tar.zst



# get hblock config
mkdir -p /etc/hblock
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/sources.list > /etc/hblock/sources.list"
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/deny.list > /etc/hblock/deny.list"
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/allow.list > /etc/hblock/allow.list"

# CHRONY CONF
license_url="https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/LICENSE"
chrony_url="https://raw.githubusercontent.com/GrapheneOS/infrastructure/refs/heads/main/etc/chrony.conf"

mkdir -p /tmp/chrony_conf/
wget -O /tmp/chrony_conf/LICENSE "$license_url"
sed 's/^/# /' /tmp/chrony_conf/LICENSE > /tmp/chrony_conf/LICENSE_temp
wget -O /tmp/chrony_conf/chrony.conf "$chrony_url"

rm -rf /etc/chrony.conf

# Build new chrony.conf
cat /tmp/chrony_conf/LICENSE_temp >> /etc/chrony.conf
cat /tmp/chrony_conf/chrony.conf >> /etc/chrony.conf

# Update chronyd
sed -i 's/^OPTIONS=.*$/OPTIONS="-F 1 -r"/' /etc/sysconfig/chronyd
