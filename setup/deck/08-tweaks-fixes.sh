#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

log "INFO" "Applying handheld specific tweaks"
if [[ -d /usr/share/ublue-os ]]; then
    # Remove stuffs
    rm -vf /usr/etc/xdg/autostart/steam.desktop
    # login manager
    sed -i 's|^Session=.*|Session=gnome-wayland.desktop|' /etc/sddm.conf.d/steamos.conf
    systemctl -v disable sddm || true
    systemctl -v enable gdm || true
fi

sed -i "s|^screen-keyboard-enabled=.*|screen-keyboard-enabled=true|" /etc/dconf/db/distro.d/defaults
sed -i "s|^toolkit-accessibility=.*|toolkit-accessibility=true|" /etc/dconf/db/distro.d/interface
sed -i "s|^text-scaling-factor=.*|text-scaling-factor=1.2|" /etc/dconf/db/distro.d/interface
cp -vaf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/

log "INFO" "Reducing ram consumption by disabling unneeded processes"
restore_point="/etc/${PROJECT_NAME}/restore-point"
mkdir -vp "${restore_point}"/{xdg-autostart,systemd-{system,user},dbus-services}
#systemctl disable systemd-nsresourced.service systemd-nsresourced.socket systemd-userdbd.service systemd-userdbd.socket
systemctl --global disable org.freedesktop.IBus.session.GNOME.service \
                               org.freedesktop.IBus.session.generic.service
systemctl --global mask org.freedesktop.IBus.session.GNOME.service \
                            org.freedesktop.IBus.session.generic.service

mv -v /usr/lib/systemd/user/org.freedesktop.IBus.session.generic.* "${restore_point}/systemd-user"
mv -v /usr/lib/systemd/user/org.freedesktop.IBus.session.GNOME.* "${restore_point}/systemd-user"
mv -v /usr/share/dbus-1/services/org.freedesktop.IBus.* "${restore_point}/dbus-services"
mv -v /usr/share/dbus-1/services/org.freedesktop.portal.IBus.* "${restore_point}/dbus-services"
log "INFO" "System tweaks applied"
