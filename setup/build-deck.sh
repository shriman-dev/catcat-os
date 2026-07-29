#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

################################
# Copying System Default Files #
################################
log "INFO" "Fetching remote configurations"
SYS_CACHE="${BUILD_CACHE_DIR}/system-${IMAGE_NAME}"
bazz_repo="ublue-os/bazzite"
remote_d="system_files/deck/shared"

declare -A remote_map=(
    ["etc/bluetooth"]="${remote_d}/etc/bluetooth:main.conf"
    ["etc/modules-load.d"]="${remote_d}/etc/modules-load.d:hid-steaminput-preload.conf"
    ["etc/systemd/logind.conf.d"]="${remote_d}/etc/systemd/logind.conf.d:deck.conf"
    ["usr/lib/udev/rules.d"]="${remote_d}/usr/lib/udev/rules.d:50-lenovo-legion-controller.rules"
    ["usr/share/color/icc/colord"]="${remote_d}/usr/share/color/icc/colord:Legion_GO_BT1886.icc"
    ["usr/share/pipewire/hardware-profiles/lenovo-83e1"]="${remote_d}/usr/share/pipewire/hardware-profiles/lenovo-83e1:multiwayCor48.wav"
    ["usr/share/pipewire/hardware-profiles/lenovo-83e1/pipewire.conf.d"]="${remote_d}/usr/share/pipewire/hardware-profiles/lenovo-83e1/pipewire.conf.d:filter-chain.conf"
)

for local_path in "${!remote_map[@]}"; do
    IFS=':' read -r repo_path filename <<< "${remote_map[${local_path}]}"
    get_ghraw --dstd "${SYS_CACHE}/${local_path}" --repo "${bazz_repo}" \
              --repod "${repo_path}" -f "${filename}"
done

get_ghraw \
    --dstd "${SYS_CACHE}/usr/share/wireplumber/hardware-profiles/lenovo-83e1/wireplumber.conf.d" \
    --repo "${bazz_repo}" \
    --repod "${remote_d}/usr/share/wireplumber/hardware-profiles/lenovo-83e1/wireplumber.conf.d" \
    --flist "51-preferHDMI.conf" "60-raise-internal-mic.conf" "alsa-card0.conf" "alsa-card1.conf"

get_ghraw \
    --dstd "${SYS_CACHE}/usr/share/wireplumber/wireplumber.conf.d" \
    --repo "${bazz_repo}" \
    --repod "${remote_d}/usr/share/wireplumber/wireplumber.conf.d" \
    --flist "alsa-card0.conf" "alsa-card1.conf" "alsa-ps-controller.conf" "bluez.conf"

log "INFO" "Copying cached files"
ocopy "${SYS_CACHE}" /
log "INFO" "Fetching done"


##############
# Debloating #
##############
#log "INFO" "Debloating..."

#log "INFO" "Debloat Done"


#######################
# Installing Packages #
#######################
COPR_LIST=(
    "rhea/acpi_call"
    "hhd-dev/hhd"
)

DECK_PACKAGES=(
#    "jupiter-fan-control"
#    "galileo-mura" # Utility designed to mitigate uneven brightness or graininess on OLED screens
#    "steamdeck-dsp"
#    "powerbuttond"
#    "inputplumber"
#    "steamos-manager-powerstation"
#    "vpower"
#    #"steam-notif-daemon"
#    "acpica-tools"
#    "sdgyrodsu"
#    "socat"
#    "python-vdf"
#    "python-crcmod"
    "hhd"
    "hhd-ui"
    "adjustor"
    "kernel-headers"
    "${CUSTOM_KERNEL:-kernel}-devel-matched"
    "acpi_call-dkms"
)

rpm_repos enable
pkgs_install "deck" "${DECK_PACKAGES[@]}"
rpm_repos disable


###########
# Network #
###########
systemctl disable dnscrypt-proxy.service
/usr/bin/localdnsctl -v --switch-backend dnsmasq
systemctl -f enable dnsmasq.service


################################
# Configuring Systemd Services #
################################
#log "INFO" "Enabling system services"

#log "INFO" "Enabled system services"

log "INFO" "Disabling and masking system services"
systemctl -v disable ds-inhibit.service || true
systemctl -v mask ds-inhibit.service || true
log "INFO" "Disabled system services"


####################
# Tweaks And Fixes #
####################
log "INFO" "Applying handheld specific tweaks"
if [[ -d /usr/share/ublue-os ]]; then
    # Remove stuffs
    rm -vf /usr/etc/xdg/autostart/steam.desktop
    # login manager
    sed -i 's/.*Session=.*/Session=gnome-wayland.desktop/g' /etc/sddm.conf.d/steamos.conf
    systemctl -v disable sddm || true
    systemctl -v enable gdm || true
fi

sed -i "s/screen-keyboard-enabled=.*/screen-keyboard-enabled=true/" /etc/dconf/db/distro.d/defaults
sed -i "s/toolkit-accessibility=.*/toolkit-accessibility=true/" /etc/dconf/db/distro.d/interface
sed -i "s/text-scaling-factor=.*/text-scaling-factor=1.2/" /etc/dconf/db/distro.d/interface
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


#######################
# Post Build Clean Up #
#######################
#log "INFO" "Running post setup cleanup"
#dnf5 -y autoremove

