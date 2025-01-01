#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"

addRepos() {
cd /etc/yum.repos.d/

curl -LO https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo
curl -LO https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-$(rpm -E %fedora)/atim-starship-fedora-$(rpm -E %fedora).repo
curl -LO https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-$(rpm -E %fedora)/atim-lazygit-fedora-$(rpm -E %fedora).repo
curl -LO https://copr.fedorainfracloud.org/coprs/zeno/scrcpy/repo/fedora-$(rpm -E %fedora)/zeno-scrcpy-fedora-$(rpm -E %fedora).repo

cd -
}
addRepos &

# debloat
rpm-ostree override remove fastfetch ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster gnome-browser-connector plocate gnome-shell-extension-just-perfection gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell gnome-shell-extension-caffeine gnome-shell-extension-compiz-alike-magic-lamp-effect gnome-shell-extension-compiz-windows-effect openssh-askpass &
#sunshine

security='firejail firewall-config'

shell='fish bat eza starship'
rpm-ostree install https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm &

diskFileMan='compsize htop btop ncdu fio fzf fd-find ripgrep zoxide dosfstools exfatprogs dmraid zstd gpart gparted'

terminalTools='aria2 asciinema brightnessctl ffmpeg hwinfo kpcli zenity parallel tealdeer which wmctrl ydotool'

funTerminalTools='asciiquarium cmatrix cava neo oneko sl cbonsai cowsay fortune-mod'

devTools='ptyxis git lazygit micro neovim tmux sassc codium'

encryptionAndBackupTools='rsync rclone cryfs borgbackup archivemount syncthing'

androidTools='android-tools scrcpy'

files='nautilus-extensions nautilus-python nemo nemo-emblems nemo-extensions nemo-gsconnect nemo-preview nemo-python sushi'

themingCompatibility='gnome-tweaks dconf-editor libgtop2 libappindicator-gtk3 gnome-menus gnome-themes-extra gtk-murrine-engine gtk2-engines glib2-devel kvantum qt5ct qt6ct qt5-qtquickcontrols2 qt5-qtsvg qt6-qtsvg menulibre awf-gtk2 awf-gtk3 awf-gtk4'
#appeditor sddm

iconsAndFonts='rsms-inter-fonts'
#papirus-icon-theme

gnomeShellExtensions='gnome-shell-extension-gsconnect'

gaming='antimicrox lutris goverlay gamescope gamemode mangohud vkBasalt fluidsynth'

virtualization='virt-manager libvirt libvirt-client libvirt-client-qemu bridge-utils qemu qemu-img qemu-kvm'

extras='bleachbit gnome-system-monitor uresourced irqbalance spectacle'

rpm-ostree install $( echo "$security" "$shell" "$diskFileMan" "$terminalTools" "$funTerminalTools" "$devTools" "$encryptionAndBackupTools" "$androidTools" "$files" "$themingCompatibility" "$iconsAndFonts" "$gnomeShellExtensions" "$gaming" "$virtualization" "$extras" )
