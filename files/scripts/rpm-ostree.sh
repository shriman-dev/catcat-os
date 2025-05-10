#!/bin/bash
set -oue pipefail 
echo -e "\n$0\n"

################
## EXTRA PKGS ##
################

eza() {
curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
mkdir -p /tmp/ezaTarExtract
tar -xf /tmp/eza.tar.gz -C /tmp/ezaTarExtract
cp -dvf /tmp/ezaTarExtract/eza /usr/bin/
chmod +x /usr/bin/eza
rm -rf /tmp/eza.tar.gz /tmp/ezaTarExtract
}

hblock() {
curl -Lo /usr/bin/hblock https://raw.githubusercontent.com/hectorm/hblock/refs/heads/master/hblock
chmod +x /usr/bin/hblock 
}

bandwhich() {
curl -Lo /tmp/bandwhich.tar.gz $(curl -s -X GET https://api.github.com/repos/imsnif/bandwhich/releases/latest | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)
mkdir -p /tmp/bandwhichTarExtract
tar -xf /tmp/bandwhich.tar.gz -C /tmp/bandwhichTarExtract
cp -dvf /tmp/bandwhichTarExtract/bandwhich /usr/bin/
chmod +x /usr/bin/bandwhich
rm -rf /tmp/bandwhich.tar.gz /tmp/bandwhichTarExtract
}

buttersnap() {
curl -Lo /usr/bin/buttersnap.sh https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main/buttersnap.sh
chmod +x /usr/bin/buttersnap.sh
}

btdu() {
curl -Lo /usr/bin/btdu https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64
chmod +x /usr/bin/btdu
}

gocryptfs() {
curl -Lo /tmp/gocryptfs.tar.gz $(curl -s -X GET https://api.github.com/repos/rfjakob/gocryptfs/releases/latest | grep -i '"browser_download_url": "[^"]*amd64.tar.gz"' | cut -d '"' -f4)
mkdir -p /tmp/gocryptfsTarExtract
tar -xf /tmp/gocryptfs.tar.gz -C /tmp/gocryptfsTarExtract
cp -dvf /tmp/gocryptfsTarExtract/gocryptfs /usr/bin/
chmod +x /usr/bin/gocryptfs
rm -rf /tmp/gocryptfs.tar.gz /tmp/gocryptfsTarExtract
}

yazi() {
curl -Lo /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
curl -Lo /usr/share/applications/yazi.desktop https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/yazi.desktop
curl -Lo /usr/share/icons/yazi.png https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/logo.png

unzip /tmp/yazi.zip
cp -dvf yazi-x86_64-unknown-linux-gnu/{ya,yazi} /usr/bin/
chmod +x /usr/bin/yazi
chmod +x /usr/bin/ya

rm -rf /tmp/yazi.zip yazi-x86_64-unknown-linux-gnu/
}

extra_pkgs() {
# ascii-image-converter
curl -Lo /tmp/ascii-image-converter.tar.gz https://github.com/TheZoraiz/ascii-image-converter/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz
mkdir -p /tmp/ascii-image-converter
tar -xf /tmp/ascii-image-converter.tar.gz -C /tmp/ascii-image-converter --strip-components=1
cp -dvf /tmp/ascii-image-converter/ascii-image-converter /usr/bin/
chmod +x /usr/bin/ascii-image-converter
rm -rf /tmp/ascii-image-converter.tar.gz /tmp/ascii-image-converter

# pipes.sh
git clone https://github.com/pipeseroni/pipes.sh.git /tmp/pipes.sh
cp -dvf /tmp/pipes.sh/pipes.sh /usr/bin/

## pokemonsay-newgenerations
#git clone https://github.com/HRKings/pokemonsay-newgenerations.git /tmp/pokemonsay-newgenerations

#cp -drf /tmp/pokemonsay-newgenerations/pokemons /usr/bin/
#cp -dvf /tmp/pokemonsay-newgenerations/pokemonsay.sh /usr/bin/
#cp -dvf /tmp/pokemonsay-newgenerations/pokemonthink.sh /usr/bin/

# extra
curl -Lo /usr/share/applications/micro.desktop https://raw.githubusercontent.com/zyedidia/micro/refs/heads/master/assets/packaging/micro.desktop

}
extra_pkgs

##############
## RPM PKGS ##
##############

addRepos() {
cd /etc/yum.repos.d/
ls -A1

#dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}
#dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade"
#dnf5 -y config-manager setopt "terra-mesa".enabled=true
#dnf5 -y config-manager setopt "terra-nvidia".enabled=false

dnf5 -y copr enable pgdev/ghostty
dnf5 -y copr enable atim/starship
#dnf5 -y copr enable atim/lazygit
dnf5 -y copr enable zeno/scrcpy

#curl -LO https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-$(rpm -E %fedora)/atim-starship-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-$(rpm -E %fedora)/atim-lazygit-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/zeno/scrcpy/repo/fedora-$(rpm -E %fedora)/zeno-scrcpy-fedora-$(rpm -E %fedora).repo
ls -A1
cd -
}
addRepos

# debloat
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
rpm-ostree override remove fastfetch plocate gnome-shell-extension-just-perfection gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell gnome-shell-extension-caffeine gnome-shell-extension-compiz-alike-magic-lamp-effect gnome-shell-extension-compiz-windows-effect openssh-askpass
#sunshine gnome-browser-connector

security='firejail firewall-config usbguard usbguard-selinux usbguard-notifier'
hblock
#curl -s -X GET https://api.github.com/repos/evilsocket/opensnitch/releases/latest | grep -i '"browser_download_url": "[^"]*.rpm"' | cut -d '"' -f4

# zellij
shellSetup='fish bat lsd starship fzf fd-find ripgrep zoxide tmux'
eza
rpm-ostree install https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm

monitoringTools='htop btop nethogs procs wireshark'
bandwhich

#dmraid
diskFileMan='compsize dua-cli gdu ncdu fio duf dosfstools exfatprogs zstd gpart gparted'
buttersnap; btdu; gocryptfs; yazi

terminalTools='aria2 asciinema brightnessctl ffmpeg inxi hwinfo kpcli zenity parallel tealdeer which wmctrl ydotool poppler wl-clipboard hyperfine'

funTerminalTools='asciiquarium cmatrix cava neo oneko sl cbonsai cowsay fortune-mod'

#ghostty
devTools='ptyxis git micro neovim sassc codium'
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)

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
