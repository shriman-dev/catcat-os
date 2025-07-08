#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -oue pipefail
echo -e "\n$0\n"

# to use catcat update
sed -i "s|Exec=.*|Exec=/usr/bin/update all|" /usr/share/applications/system-update.desktop

# topgrade setup
sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' /usr/share/ublue-os/just/10-update.just
sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true

# enable disk discard
sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# libvirt setup
sed -i 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' /etc/libvirt/libvirtd.conf
sed -i 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf

# Fix issues caused by ID no longer being fedora
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

#fix librewolf/firefox delayed launch issue
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

# amd gpu opergb support
#kernel="$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | grep 'bazzite')"

#git clone https://github.com/twifty/amd-gpu-i2c.git /tmp/amd-gpu-i2c
#cd /tmp/amd-gpu-i2c
#sed -i "s|sudo insmod \$(MODULE_NAME).ko|cp \$(MODULE_NAME).ko /lib/modules/$kernel/extra/|" ./Makefile
#sed -i "s/sudo //g" ./Makefile
#sed -i "s/\$(shell uname -r)/$kernel/" ./Makefile

#make install

#echo "amdgpu-i2c" > /etc/modules-load.d/amdgpu-i2c.conf # make it persistant

# handheld specific tweaks
if command -v hhdctl; then
    rm -vf /usr/etc/xdg/autostart/steam.desktop
    # login manager
    sed -i 's/.*Session=.*/Session=gnome-wayland.desktop/g' /etc/sddm.conf.d/steamos.conf
    systemctl disable sddm
    systemctl enable gdm
    # edit /etc/gdm/custom.conf
    sed -i "/enabled-extensions=/ { s/']/, 'gjsosk@vishram1123.com']/ }" /etc/dconf/db/distro.d/extensions
    sed -i "s/screen-keyboard-enabled=.*/screen-keyboard-enabled=true/" /etc/dconf/db/distro.d/defaults
    sed -i "s/toolkit-accessibility=.*/toolkit-accessibility=true/" /etc/dconf/db/distro.d/interface
    sed -i "s/text-scaling-factor=.*/text-scaling-factor=1.2/" /etc/dconf/db/distro.d/interface
    cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/
    # extension
    sed -i "s/this.monitor.width.*sf,/this.monitor.width * 0.01, 1 * sf,/" /etc/skel/.local/share/gnome-shell/extensions/touchup@mityax/features/navigationBar/widgets/gestureNavigationBar.js
    sed -i "s/Math.min(height.*sf,/Math.min(height * 0.01, 1 * sf,/" /etc/skel/.local/share/gnome-shell/extensions/touchup@mityax/features/navigationBar/widgets/gestureNavigationBar.js
fi
