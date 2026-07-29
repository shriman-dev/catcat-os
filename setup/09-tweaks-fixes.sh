#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

# TWEAKS
log "INFO" "Applying system tweaks"

# Rpm-ostreed auto update policy to be none
log "INFO" "Updating update policy"
sed -i 's|AutomaticUpdatePolicy=.*|AutomaticUpdatePolicy=none|g' /etc/rpm-ostreed.conf

# Enable disk discard
log "INFO" "Enabling support for disk discard"
sed -i "s|.*issue_discards =.*|issue_discards = 1|" /etc/lvm/lvm.conf

# Libvirt setup
if [[ -f /etc/libvirt/libvirtd.conf ]]; then
    log "INFO" "Setting up libvirtd.conf"
    sed -i -e 's|.*unix_sock_group =.*|unix_sock_group = "libvirt"|' \
           -e 's|.*unix_sock_rw_perms =.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf
fi

# Ignore inhabitors for suspend
#log "INFO" "Tweaking logind to ignore inhabitors for suspend"
#sed -i "s|.*SuspendKeyIgnoreInhibited=.*|SuspendKeyIgnoreInhibited=yes|" /usr/lib/systemd/logind.conf
#sed -i "s|.*MemorySleepMode=.*|MemorySleepMode=deep|" /usr/lib/systemd/sleep.conf

# Copy over logind.conf and sleep.conf for ease of access
log "INFO" "Copying over logind.conf and sleep.conf for ease of access"
mkdir -vp /etc/systemd/{logind.conf.d,sleep.conf.d}
cp -vf /usr/lib/systemd/logind.conf /etc/systemd/logind.conf.d/logind.conf.example
cp -vf /usr/lib/systemd/sleep.conf /etc/systemd/sleep.conf.d/sleep.conf.example

# PERFORMANCE TWEAKS
log "INFO" "Applying performance tweaks"
# Configure zram and reduce ram consumption by disabling unneeded process
check_file_inplace /usr/lib/systemd/zram-generator.conf
check_file_inplace /usr/lib/sysctl.d/65-memory.conf

# Disable ibus (causes input lag when selected)
#chmod -v 000 /usr/bin/ibus
#chmod -v 000 /usr/bin/ibus-daemon
#chmod -v 000 /usr/bin/ibus-setup
#chmod -v 000 /usr/libexec/evolution-source-registry
#chmod -v 000 /usr/libexec/evolution-addressbook-factory
#chmod -v 000 /usr/libexec/evolution-calendar-factory
#chmod -v 000 /usr/libexec/evolution-data-server/evolution-alarm-notify
log "INFO" "Reducing ram consumption by disabling unneeded processes"
restore_point="/etc/${PROJECT_NAME}/restore-point"
mkdir -vp "${restore_point}"/{xdg-autostart,systemd-{system,user},dbus-services}

chmod -v 000 /usr/libexec/gsd-printer || true
chmod -v 000 /usr/libexec/gsd-sharing || true
chmod -v 000 /usr/libexec/gsd-wacom || true
chmod -v 000 /usr/libexec/goa-daemon || true
chmod -v 000 /usr/libexec/goa-identity-service || true

sed -i '/Restart=on-failure/d' /usr/lib/systemd/user/org.gnome.SettingsDaemon.Wacom.service || true
sed -i '/Restart=on-failure/d' /usr/lib/systemd/user/org.gnome.SettingsDaemon.Sharing.service || true
log "INFO" "System tweaks applied"

# FIXES
log "INFO" "Applying system fixes"
# Fix if dconf user profile does not exists or is not configured for distro db
dconf_profile="/etc/dconf/profile/user"
if [[ ! -f "${dconf_profile}" ]]; then
    mkdir -vp "$(direname "${dconf_profile}")"
    echo "user-db:user
system-db:local
system-db:site
system-db:distro" > "${dconf_profile}"
elif ! grep -xF "system-db:distro" "${dconf_profile}"; then
    echo "system-db:distro" >> "${dconf_profile}"
fi

# Fix issues caused by ID no longer being fedora
log "INFO" "Fixing issues caused by ID no longer being fedora"
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

# Fix librewolf/firefox delayed launch issue
log "INFO" "Fixing librewolf/firefox delayed launch issue"
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

# Fix iso installation failing for the reason just having CN readme
rpm -q just &&
    rm -v /usr/share/doc/just/README.*.md

log "INFO" "System fixes applied"
