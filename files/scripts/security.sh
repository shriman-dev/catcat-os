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

# Ad/Malware blocking with dnsmasq using networkmanager
mkdir -p /etc/NetworkManager/conf.d
sh -c "echo '[main]
dns=dnsmasq' > /etc/NetworkManager/conf.d/00-use-dnsmasq.conf"

mkdir -p /etc/NetworkManager/dnsmasq.d/blocklist.d
sh -c "echo '# defaults
domain-needed
bogus-priv
no-resolv
bind-interfaces
conf-dir=/etc/NetworkManager/dnsmasq.d/blocklist.d
addn-hosts=/etc/hosts' > /etc/NetworkManager/dnsmasq.d/00-defaults.conf"

curl -Lo /tmp/dnsmasq.d.tar.zst https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/dnsmasq.d.tar.zst
tar --use-compress-program "zstd -d" -xvf "/tmp/dnsmasq.d.tar.zst" -C /etc/NetworkManager/dnsmasq.d/blocklist.d/ --strip-components=1

tree /etc/NetworkManager/dnsmasq.d/

# get hblock config
mkdir -p /etc/hblock
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/sources.list > /etc/hblock/sources.list"
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/deny.list > /etc/hblock/deny.list"
sh -c "curl -sf https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main/hblock/allow.list > /etc/hblock/allow.list"

# CHRONY CONF
license_url="https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/LICENSE"
chrony_url="https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf"

mkdir -p /tmp/chrony_conf/
wget -q -O /tmp/chrony_conf/LICENSE "$license_url"
sed 's/^/# /' /tmp/chrony_conf/LICENSE > /tmp/chrony_conf/LICENSE_temp
wget -q -O /tmp/chrony_conf/chrony.conf "$chrony_url"

rm -rf /etc/chrony.conf

# Build new chrony.conf
cat /tmp/chrony_conf/LICENSE_temp >> /etc/chrony.conf
cat /tmp/chrony_conf/chrony.conf >> /etc/chrony.conf

# Update chronyd
sed -i 's/^OPTIONS=.*$/OPTIONS="-F 1 -r"/' /etc/sysconfig/chronyd
