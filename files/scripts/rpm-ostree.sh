#!/bin/bash
set -oue pipefail
echo -e "\n$0\n"

################
## EXTRA PKGS ##
################

#eza() {
#curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
#mkdir -p /tmp/ezaTarExtract
#tar -xf /tmp/eza.tar.gz -C /tmp/ezaTarExtract
#cp -dvf /tmp/ezaTarExtract/eza /usr/bin/
#chmod +x /usr/bin/eza
#rm -rf /tmp/eza.tar.gz /tmp/ezaTarExtract
#}

#bandwhich() {
#curl -Lo /tmp/bandwhich.tar.gz $(curl -s -X GET https://api.github.com/repos/imsnif/bandwhich/releases/latest | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)
#mkdir -p /tmp/bandwhichTarExtract
#tar -xf /tmp/bandwhich.tar.gz -C /tmp/bandwhichTarExtract
#cp -dvf /tmp/bandwhichTarExtract/bandwhich /usr/bin/
#chmod +x /usr/bin/bandwhich
#rm -rf /tmp/bandwhich.tar.gz /tmp/bandwhichTarExtract
#}

#btdu() {
#curl -Lo /usr/bin/btdu https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64
#chmod +x /usr/bin/btdu
#}

#gocryptfs() {
#curl -Lo /tmp/gocryptfs.tar.gz $(curl -s -X GET https://api.github.com/repos/rfjakob/gocryptfs/releases/latest | grep -i '"browser_download_url": "[^"]*amd64.tar.gz"' | cut -d '"' -f4)
#mkdir -p /tmp/gocryptfsTarExtract
#tar -xf /tmp/gocryptfs.tar.gz -C /tmp/gocryptfsTarExtract
#cp -dvf /tmp/gocryptfsTarExtract/gocryptfs /usr/bin/
#chmod +x /usr/bin/gocryptfs
#rm -rf /tmp/gocryptfs.tar.gz /tmp/gocryptfsTarExtract
#}

hblock() {
curl -Lo /usr/bin/hblock https://raw.githubusercontent.com/hectorm/hblock/refs/heads/master/hblock
chmod +x /usr/bin/hblock
}

buttersnap() {
curl -Lo /usr/bin/buttersnap.sh https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main/buttersnap.sh
curl -Lo /usr/bin/buttercopy.sh https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main/buttercopy.sh
chmod +x /usr/bin/buttersnap.sh
chmod +x /usr/bin/buttercopy.sh
}

llama_cpp() {
curl -Lo /tmp/llama_cccppp.zip $(curl -s -X GET https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | grep -i '"browser_download_url": "[^"]*ubuntu-vulkan-x64.zip"' | cut -d '"' -f4)

mkdir -vp /tmp/llama_cccppp /usr/libexec/llama_cpp_vulkan
cd /tmp/llama_cccppp
unzip /tmp/llama_cccppp.zip

mv -v /tmp/llama_cccppp/build/bin /usr/libexec/llama_cpp_vulkan/

ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-batched-bench /usr/bin/
ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-bench /usr/bin/
ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-cli /usr/bin/
#ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-imatrix /usr/bin/
#ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-gguf-split /usr/bin/
ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-mtmd-cli /usr/bin/
#ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-quantize /usr/bin/
ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-run /usr/bin/
ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-server /usr/bin/
#ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-tokenize /usr/bin/
#ln -svf /usr/libexec/llama_cpp_vulkan/bin/llama-tts /usr/bin/
cd -
}

yazi() {
curl -Lo /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
curl -Lo /usr/share/applications/yazi.desktop https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/yazi.desktop
curl -Lo /usr/share/icons/yazi.png https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/logo.png

unzip /tmp/yazi.zip
cp -dvf yazi-x86_64-unknown-linux-gnu/{ya,yazi} /usr/bin/
chmod +x /usr/bin/{ya,yazi}

rm -rf /tmp/yazi.zip yazi-x86_64-unknown-linux-gnu/
}

mfancontrol() {
curl -Lo /tmp/MControlCenterrrr $(curl -s -X GET https://api.github.com/repos/dmitry-s93/MControlCenter/releases/latest | grep -i '"browser_download_url": "[^"]*.tar.gz"' | cut -d '"' -f4)

mkdir -p /tmp/MControlCenter
tar -xf /tmp/MControlCenterrrr -C /tmp/MControlCenter --strip-components=1
cd /tmp/MControlCenter/
/tmp/MControlCenter/install.sh
cd -
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

add_repos() {
cd /etc/yum.repos.d/
ls -A1

#dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}
#dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade"
#dnf5 -y config-manager setopt "terra-mesa".enabled=true
#dnf5 -y config-manager setopt "terra-nvidia".enabled=false

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/terra.repo
dnf5 -y copr enable kylegospo/unl0kr
dnf5 -y copr enable pgdev/ghostty
dnf5 -y copr enable atim/starship
dnf5 -y copr enable zeno/scrcpy
#dnf5 -y copr enable atim/lazygit

#curl -LO https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-$(rpm -E %fedora)/atim-starship-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-$(rpm -E %fedora)/atim-lazygit-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/zeno/scrcpy/repo/fedora-$(rpm -E %fedora)/zeno-scrcpy-fedora-$(rpm -E %fedora).repo
ls -A1
cd -
}
add_repos

# debloat
#ibus-libpinyin ibus-hangul ibus-m17n ibus-mozc ibus-typing-booster
sed -i 's|gnome-software ||' /etc/dnf/repos.override.d/99-config_manager.repo
dnf5 -y remove bazaar topgrade fastfetch plocate gnome-shell-extension-just-perfection gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell gnome-shell-extension-caffeine gnome-shell-extension-compiz-alike-magic-lamp-effect gnome-shell-extension-compiz-windows-effect openssh-askpass nvtop tailscale libvirt-libs libvirt sunshine steamdeck-backgrounds stress-ng webapp-manager fedora-workstation-backgrounds uupd yelp gnome-browser-connector gnome-initial-setup $(rpm -E %fedora)-backgrounds-base btrfs-assistant

security='firejail firewall-config usbguard usbguard-selinux usbguard-notifier pam_mount lynis'
hblock
#rpm-ostree install $(curl -s -X GET https://api.github.com/repos/evilsocket/opensnitch/releases/latest | grep -i '"browser_download_url": "[^"]*.noarch.rpm"' | cut -d '"' -f4)

shellSetup='nu fish bat lsd starship fzf fd-find ripgrep zoxide tmux eza zellij'
rpm-ostree install https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm

monitoringTools='lm_sensors s-tui powertop htop btop nethogs procs wireshark bandwhich'

#dmraid
diskFileMan='compsize dua-cli gdu ncdu fio duf dosfstools exfatprogs zstd gpart gparted btdu gocryptfs'
buttersnap; yazi

terminalTools='aria2 asciinema brightnessctl ffmpeg ffmpegthumbnailer inxi hwinfo memtester nvme-cli kpcli zenity parallel tealdeer which wmctrl ydotool poppler wl-clipboard hyperfine jq zsync'
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/watchexec/watchexec/releases/latest | grep -i '"browser_download_url": "[^"]*-x86_64-unknown-linux-gnu.rpm"' | cut -d'"' -f4)

funTerminalTools='asciiquarium cmatrix cava neo oneko sl cbonsai cowsay fortune-mod'

#lazygit
devTools='criu criu-amdgpu-plugin ptyxis ghostty git micro neovim sassc codium'
llama_cpp
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)

encryptionAndBackupTools='rsync rclone cryfs borgbackup archivemount syncthing'

androidTools='android-tools scrcpy'

files='nautilus-extensions nautilus-python nemo nemo-emblems nemo-extensions nemo-preview nemo-python sushi'
#nemo-gsconnect

themingCompatibility='gnome-tweaks dconf-editor libgtop2 libappindicator-gtk3 gnome-menus gnome-themes-extra gtk-murrine-engine gtk2-engines glib2-devel kvantum qt5ct qt6ct qt5-qtquickcontrols2 qt5-qtsvg qt6-qtsvg menulibre awf-gtk2 awf-gtk3 awf-gtk4'
#appeditor sddm

iconsAndFonts='rsms-inter-fonts'
#papirus-icon-theme

gnomeShellExtensions='gnome-shell-extension-gsconnect'

#corectrl
gaming='antimicrox lutris goverlay gamescope gamemode mangohud vkBasalt fluidsynth openrgb liquidctl coolercontrol'
mfancontrol
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/Umio-Yasuno/amdgpu_top/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d '"' -f4)
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -i '"browser_download_url": "[^"]*'$(rpm -E %fedora)'.rpm"' | grep -v "headless" | cut -d '"' -f4)
#rpm-ostree install $(curl -s -X GET https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)

# virt-manager gnome-boxes
virtualization='edk2-ovmf genisoimage qemu qemu-img qemu-kvm quickemu socat spice-gtk-tools swtpm swtpm-tools'

extras='bleachbit gnome-system-monitor gnome-software uresourced irqbalance xed'

all_pkgs=(
    "${security[@]}"
    "${shellSetup[@]}"
    "${monitoringTools[@]}"
    "${diskFileMan[@]}"
    "${terminalTools[@]}"
    "${funTerminalTools[@]}"
    "${devTools[@]}"
    "${encryptionAndBackupTools[@]}"
    "${androidTools[@]}"
    "${files[@]}"
    "${themingCompatibility[@]}"
    "${iconsAndFonts[@]}"
    "${gnomeShellExtensions[@]}"
    "${gaming[@]}"
    "${virtualization[@]}"
    "${extras[@]}"
)

echo "all_pkgs: ${all_pkgs[@]}"
rpm-ostree install ${all_pkgs[@]}
