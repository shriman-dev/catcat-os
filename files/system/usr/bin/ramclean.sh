#!/bin/bash
sync; echo 3 > '/proc/sys/vm/drop_caches' #&& swapoff -a && swapon -a

KILLP='gnome-software
evolution-alarm-notify
tracker-miner-fs-3
evolution-source-registry
gsd-wacom
evolution-calendar-factory
evolution-addressbook-factory
gsd-printer
qojop
fwupd
updatedb
kdeconnectd
ibus
setroubleshootd
gnome-calendar'
#sssd_kcm
#gvfsd-http
#avahi-daemon
#gsd-media-key
#abrt-applet
#gsd-smartcard
#gsd-sharing
#gsd-screensaver-proxy
#cupsd
#gvfs-goa-volume-monitor
#gvfsd-dnssd
#gsd-power
#abrt-dump-journal-xorg
#abrtd
#dconf-service
#colord
#xdg-desktop-portal-gnome
#gvfsd
#gsd-housekeeping
#gsd-color
#ibus-x11
#ibus-extention-gtk3
#goa-daemon
#goa-identity
#gsd-print-notifications
#gsd-datetime
#gsd-keyboard
#gsd-daemon
#gnome-keyring-daemon
#xdg-desktop-portal-gtk
#gsd-xsettings

for II in ${KILLP[*]}
do 
  pkill -KILL -fe $II
done

exit 0
