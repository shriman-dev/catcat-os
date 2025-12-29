#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

log "INFO" "Running post build image cleanup"
dnf5 clean all
rm -rf /tmp/* || true
find /var/* -maxdepth 0 -type d -not -name "cache" -exec rm -rf {} \;
find /var/cache/* -maxdepth 0 -type d -not -name "libdnf5" -not -name "rpm-ostree" -exec rm -rf {} \;

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

mkdir -p /var/tmp
chmod -R 1777 /var/tmp
