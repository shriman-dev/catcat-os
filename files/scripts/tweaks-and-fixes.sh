#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

# Tweak ublue defaults
if [[ -d /usr/share/ublue-os ]]; then
    log "INFO" "Tweaking ublue/bazzite defaults"
    sed -i 's|/usr/bin/topgrade.*|/usr/bin/topgrade --no-self-update --yes --cleanup --only flatpak nix firmware|' \
        /usr/share/ublue-os/just/10-update.just || true
    sed -i 's/"pip3", //g' /usr/share/ublue-os/topgrade.toml || true
fi

# Rpm-ostreed auto update policy to be none
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
log "INFO" "Tweaking logind to ignore inhabitors for suspend"
sed -i "s|.*SuspendKeyIgnoreInhibited=.*|SuspendKeyIgnoreInhibited=yes|" /usr/lib/systemd/logind.conf
#sed -i "s|.*MemorySleepMode=.*|MemorySleepMode=deep|" /usr/lib/systemd/sleep.conf

# Copy over logind.conf and sleep.conf for ease of access
log "INFO" "Copying over logind.conf and sleep.conf for ease of access"
mkdir -vp /etc/systemd/logind.conf.d/ /etc/systemd/sleep.conf.d/
cp -drvf /usr/lib/systemd/logind.conf /etc/systemd/logind.conf.d/
cp -drvf /usr/lib/systemd/sleep.conf /etc/systemd/sleep.conf.d/

# Remove stuffs
#/etc/skel/.config/autostart
log "INFO" "Removing stuffs"
rm -rvf /etc/skel/.mozilla /etc/skel/.config/user-tmpfiles.d
# Disable gnome software running in background
if [[ -f /etc/xdg/autostart/org.gnome.Software.desktop ]]; then
    log "INFO" "Disabling gnome software from running in background"
    rm -vf /etc/xdg/autostart/org.gnome.Software.desktop
    rm -vf /usr/etc/xdg/autostart/org.gnome.Software.desktop
fi

# Handheld specific tweaks
if command -v hhdctl; then
    log "INFO" "Applying handheld specific tweaks"
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

# FIXES
# Fix issues caused by ID no longer being fedora
log "INFO" "Fixing issues caused by ID no longer being fedora"
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg

# Fix librewolf/firefox delayed launch issue
log "INFO" "Fixing librewolf/firefox delayed launch issue"
#'/^hosts:/ s/mdns4_minimal/myhostname &/'
sed -i '/^hosts:/ s/myhostname//; /^hosts:.*files\s\+myhostname/! s/mdns4_minimal/myhostname &/' /etc/nsswitch.conf

log "INFO" "All done."
