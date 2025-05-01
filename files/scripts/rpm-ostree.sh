#!/bin/bash
set -oue pipefail 
echo -e "\n$0\n"

addRepos() {
cd /etc/yum.repos.d/
ls -A1

#dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}
#dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade"
#dnf5 -y config-manager setopt "terra-mesa".enabled=true
#dnf5 -y config-manager setopt "terra-nvidia".enabled=false

dnf5 -y copr enable atim/starship
dnf5 -y copr enable atim/lazygit
dnf5 -y copr enable zeno/scrcpy
dnf5 -y copr enable pesader/hblock

#curl -LO https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-$(rpm -E %fedora)/atim-starship-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-$(rpm -E %fedora)/atim-lazygit-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/zeno/scrcpy/repo/fedora-$(rpm -E %fedora)/zeno-scrcpy-fedora-$(rpm -E %fedora).repo
ls -A1
cd -
}
addRepos

# debloat
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
rpm-ostree override remove fastfetch gnome-browser-connector plocate gnome-shell-extension-just-perfection gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell gnome-shell-extension-caffeine gnome-shell-extension-compiz-alike-magic-lamp-effect gnome-shell-extension-compiz-windows-effect openssh-askpass
#sunshine

security='firejail firewall-config usbguard usbguard-selinux usbguard-notifier hblock'
#curl -s -X GET https://api.github.com/repos/evilsocket/opensnitch/releases/latest | grep -i '"browser_download_url": "[^"]*.rpm"' | cut -d '"' -f4

shellSetup='fish bat eza starship fzf fd-find ripgrep zoxide tmux zellij'
rpm-ostree install https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm

monitoringTools='htop btop bandwhich nethogs procs wireshark'

#dmraid
diskFileMan='compsize dua-cli gdu ncdu fio duf dosfstools exfatprogs zstd gpart gparted'

terminalTools='aria2 asciinema brightnessctl ffmpeg hwinfo kpcli zenity parallel tealdeer which wmctrl ydotool inxi poppler wl-clipboard hyperfine'

funTerminalTools='asciiquarium cmatrix cava neo oneko sl cbonsai cowsay fortune-mod'

devTools='ptyxis git lazygit micro neovim sassc codium ghostty'

encryptionAndBackupTools='rsync rclone cryfs borgbackup archivemount syncthing'

androidTools='android-tools scrcpy'

files='nautilus-extensions nautilus-python nemo nemo-emblems nemo-extensions nemo-gsconnect nemo-preview nemo-python sushi'

themingCompatibility='gnome-tweaks dconf-editor libgtop2 libappindicator-gtk3 gnome-menus gnome-themes-extra gtk-murrine-engine gtk2-engines glib2-devel kvantum qt5ct qt6ct qt5-qtquickcontrols2 qt5-qtsvg qt6-qtsvg menulibre awf-gtk2 awf-gtk3 awf-gtk4'
#appeditor sddm

iconsAndFonts='rsms-inter-fonts'
#papirus-icon-theme

gnomeShellExtensions='gnome-shell-extension-gsconnect'

gaming='antimicrox lutris goverlay gamescope gamemode mangohud vkBasalt fluidsynth lm_sensors'

virtualization='gnome-boxes virt-manager libvirt libvirt-client libvirt-client-qemu bridge-utils qemu qemu-img qemu-kvm'

extras='bleachbit gnome-system-monitor uresourced irqbalance xed'

rpm-ostree install --assumeyes $( echo "$security" "$shellSetup" "$monitoringTools" "$diskFileMan" "$terminalTools" "$funTerminalTools" "$devTools" "$encryptionAndBackupTools" "$androidTools" "$files" "$themingCompatibility" "$iconsAndFonts" "$gnomeShellExtensions" "$gaming" "$virtualization" "$extras" )
