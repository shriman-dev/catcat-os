#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

# TWEAKS
log "INFO" "Making system tweaks"

# Tweak ublue defaults
if [[ -d /usr/share/ublue-os ]]; then
    log "INFO" "Tweaking ublue/bazzite defaults"
    sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' \
        /usr/share/ublue-os/just/10-update.just || true
    sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true
fi

# Rpm-ostreed auto update policy to be none
log "INFO" "Updating update policy"
sed -i 's|AutomaticUpdatePolicy=.*|AutomaticUpdatePolicy=none|g' /etc/rpm-ostreed.conf

# Enable disk discard
log "INFO" "Enabling support for disk discard"
sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# Libvirt setup
if [[ -f /etc/libvirt/libvirtd.conf ]]; then
    log "INFO" "Setting up libvirtd.conf"
    sed -i  -e 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' \
            -e 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf
fi

# Ignore inhabitors for suspend
#log "INFO" "Tweaking logind to ignore inhabitors for suspend"
#sed -i "s|.*SuspendKeyIgnoreInhibited=.*|SuspendKeyIgnoreInhibited=yes|" /usr/lib/systemd/logind.conf
#sed -i "s|.*MemorySleepMode=.*|MemorySleepMode=deep|" /usr/lib/systemd/sleep.conf

# Copy over logind.conf and sleep.conf for ease of access
log "INFO" "Copying over logind.conf and sleep.conf for ease of access"
mkdir -vp /etc/systemd/{logind.conf.d,sleep.conf.d}
cp -drvf /usr/lib/systemd/logind.conf /etc/systemd/logind.conf.d/
cp -drvf /usr/lib/systemd/sleep.conf /etc/systemd/sleep.conf.d/

# Configure zram and reduce ram consumption by disabling unneeded process
log "INFO" "Checking zram compression"
check_file_inplace /etc/systemd/zram-generator.conf

# Disable ibus (causes input lag when selected)
#chmod -v 000 /usr/bin/ibus
#chmod -v 000 /usr/bin/ibus-daemon
#chmod -v 000 /usr/bin/ibus-setup
#chmod -v 000 /usr/libexec/evolution-source-registry
#chmod -v 000 /usr/libexec/evolution-addressbook-factory
#chmod -v 000 /usr/libexec/evolution-calendar-factory
#chmod -v 000 /usr/libexec/evolution-data-server/evolution-alarm-notify
log "INFO" "Reducing ram consumption by disabling unneeded processes"
restore_point="/etc/catcat-os/restore-point"
mkdir -vp "${restore_point}"/{xdg-autostart,systemd-{system,user},dbus-services}

chmod -v 000 /usr/libexec/gsd-printer || true
chmod -v 000 /usr/libexec/gsd-sharing || true
chmod -v 000 /usr/libexec/gsd-wacom || true
chmod -v 000 /usr/libexec/goa-daemon || true
chmod -v 000 /usr/libexec/goa-identity-service || true

sed -i '/Restart=on-failure/d' /usr/lib/systemd/user/org.gnome.SettingsDaemon.Wacom.service || true
sed -i '/Restart=on-failure/d' /usr/lib/systemd/user/org.gnome.SettingsDaemon.Sharing.service || true

# Mi catcat specific tweaks
if [[ "${IMAGE_NAME}" =~ "-mi" ]] || command -v hhdctl; then
    log "INFO" "Applying image specific tweaks: ${IMAGE_NAME}"
#    systemctl disable systemd-nsresourced.service systemd-nsresourced.socket systemd-userdbd.service systemd-userdbd.socket
    systemctl --global disable org.freedesktop.IBus.session.GNOME.service \
                               org.freedesktop.IBus.session.generic.service
    systemctl --global mask org.freedesktop.IBus.session.GNOME.service \
                            org.freedesktop.IBus.session.generic.service

    mv -v /usr/lib/systemd/user/org.freedesktop.IBus.session.generic.* "${restore_point}/systemd-user"
    mv -v /usr/lib/systemd/user/org.freedesktop.IBus.session.GNOME.* "${restore_point}/systemd-user"
    mv -v /usr/share/dbus-1/services/org.freedesktop.IBus.* "${restore_point}/dbus-services"
    mv -v /usr/share/dbus-1/services/org.freedesktop.portal.IBus.* "${restore_point}/dbus-services"
fi

# Handheld specific tweaks
if command -v hhdctl; then
    log "INFO" "Applying handheld specific tweaks: ${IMAGE_NAME}"
    # Remove stuffs and disable services
    systemctl disable ds-inhibit.service
    systemctl mask ds-inhibit.service
    rm -vf /usr/etc/xdg/autostart/steam.desktop
    # login manager
    sed -i 's/.*Session=.*/Session=gnome-wayland.desktop/g' /etc/sddm.conf.d/steamos.conf
    systemctl disable sddm
    systemctl enable gdm
    sed -i "s/screen-keyboard-enabled=.*/screen-keyboard-enabled=true/" /etc/dconf/db/distro.d/defaults
    sed -i "s/toolkit-accessibility=.*/toolkit-accessibility=true/" /etc/dconf/db/distro.d/interface
    sed -i "s/text-scaling-factor=.*/text-scaling-factor=1.2/" /etc/dconf/db/distro.d/interface
    cp -drvf /etc/dconf/db/distro.d/{interface,defaults} /etc/dconf/db/gdm.d/
    # extension
    #
fi

log "INFO" "System tweaks applied"

# FIXES
log "INFO" "Applying system fixes"
# Fix issues caused by ID no longer being fedora
log "INFO" "Fixing issues caused by ID no longer being fedora"
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

# Fix librewolf/firefox delayed launch issue
log "INFO" "Fixing librewolf/firefox delayed launch issue"
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

# Fix iso build failing for the reason just having CN readme
rpm -q just &&
    rm -v /usr/share/doc/just/README.*.md

log "INFO" "System fixes applied"
