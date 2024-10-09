#!/usr/bin/bash

# GLOBAL
KARGS=$(rpm-ostree kargs)
NEEDED_KARGS=()

# KERNEL ARGUMENTS
echo "Current kargs: $KARGS"

replace-x-add() {
grep -qi ''${1}'' ${3} && sed -i -e "s|.*${1}.*|${2}|" ${3} || sh -c "echo '${2}' >> ${3}"
}

if [ ! -f '/etc/catcat-os' ]; then
mkdir -p /boot/grub_themes
cp -rf /usr/share/grub/themes/* /boot/grub_themes

replace-x-add 'GRUB_TIMEOUT=' 'GRUB_TIMEOUT=1' /etc/default/grub
replace-x-add 'GRUB_GFXPAYLOAD_LINUX=' 'GRUB_GFXPAYLOAD_LINUX=keep' /etc/default/grub
replace-x-add 'GRUB_GFXMODE=' 'GRUB_GFXMODE='$(xdpyinfo | grep -oP 'dimensions:\s+\K\S+') /etc/default/grub
replace-x-add 'GRUB_TERMINAL_OUTPUT=' 'GRUB_TERMINAL_OUTPUT=gfxterm' /etc/default/grub
replace-x-add 'GRUB_THEME=' 'GRUB_THEME="/boot/grub_themes/catppuccin-mocha-grub-theme/theme.txt"' /etc/default/grub
grub2-editenv - unset menu_auto_hide
grub2-switch-to-blscfg
grub2-mkconfig -o /etc/grub2.cfg

plymouth-set-default-theme catppuccin-mocha
rpm-ostree initramfs --enable

hostnamectl set-hostname --static "catcat"

echo 'first boot' > /etc/catcat-os

fi

KARGS_TO_ADD=(
  "rd.luks=discard"
  "rd.udev.log_priority=3"
  "loglevel=3"
  "sysrq_always_enabled=1"
  "amdgpu.ppfeaturemask=0xffffffff"
  "processor.ignore_ppc=1"
  "split_lock_detect=off"
  "pci=noats"
  "bluetooth.disable_ertm=1"
  "preempt=full"
  "mem_sleep_default=deep"
)

for karg in "${KARGS_TO_ADD[@]}"; do
  if [[ ! $KARGS =~ $karg ]]; then
    echo "Adding needed kargs for $karg"
    NEEDED_KARGS+=("--append-if-missing=$karg")
  fi
done

if [[ $KARGS =~ "nomodeset" ]]; then
  echo "Removing nomodeset"
  NEEDED_KARGS+=("--delete-if-present=nomodeset")
fi

if [[ -n "$NEEDED_KARGS" ]]; then
  echo "Found needed karg changes, applying the following: ${NEEDED_KARGS[*]}"
  plymouth display-message --text="Updating kargs - Please wait, this may take a while" || true
  rpm-ostree kargs ${NEEDED_KARGS[*]} || exit 1
else
  echo "No karg changes needed"
fi



# HOSTNAME FIX
# If the hostname is too long Distrobox will fail during setup
# Let's check the length and reset it to something sensible if that happens.
if (( $(hostname | wc -m) > 20 )); then
  hostnamectl set-hostname catcat
fi

# Set default target to graphical, fixes rebase from base image
if grep -qv "graphical.target" <<< "$(systemctl get-default)"; then
  systemctl set-default graphical.target
fi
