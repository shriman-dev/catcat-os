#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

log "INFO" "Adding extra RPM repos"
sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/terra.repo

#dnf5 -y copr enable kylegospo/unl0kr
#dnf5 -y copr enable scottames/ghostty
#dnf5 -y copr enable atim/starship
#dnf5 -y copr enable zeno/scrcpy
#dnf5 -y copr enable atim/lazygit

#cd /etc/yum.repos.d/
#curl -LO https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-$(rpm -E %fedora)/atim-starship-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-$(rpm -E %fedora)/atim-lazygit-fedora-$(rpm -E %fedora).repo
#curl -LO https://copr.fedorainfracloud.org/coprs/zeno/scrcpy/repo/fedora-$(rpm -E %fedora)/zeno-scrcpy-fedora-$(rpm -E %fedora).repo
#cd -

log "INFO" "Performing updates"
dnf5 upgrade --refresh --assumeyes

security='firewalld firewall-config usbguard usbguard-selinux usbguard-notifier' # hblock
#opensnitch

shell_setup='fish starship bat ripgrep fd-find tmux nu fzf lsd zellij zoxide ' # eza fastfetch

monitoring_tools='lm_sensors s-tui powertop htop btop nethogs procs wireshark' # bandwhich

#dmraid
disk_file_managers='compsize dua-cli gdu ncdu fio dosfstools exfatprogs zstd gpart gparted' # buttersnap btdu gocryptfs yazi

stressers_testers='memtester hyperfine parallel'

info_fetchers='inxi hwinfo nvme-cli tealdeer which'

terminal_tools='aria2 asciinema brightnessctl ffmpeg ffmpegthumbnailer kpcli zenity wmctrl ydotool poppler wl-clipboard jq zsync croc' # watchexec

fun_trerminal='asciiquarium cmatrix cava neo oneko sl cbonsai cowsay fortune-mod' # pipes.sh ascii_image_converter

#lazygit
dev_tools='criu criu-amdgpu-plugin ptyxis ghostty git micro neovim sassc' # llama_cpp vscodium

android_tools='android-tools scrcpy'

encryption_backup='rsync rclone cryfs borgbackup archivemount syncthing'

gui_file_managers='nautilus-extensions nautilus-python nemo nemo-emblems nemo-extensions nemo-preview nemo-python sushi'
#nemo-gsconnect

theming_compatibility='gnome-tweaks dconf-editor libgtop2 libappindicator-gtk3 gnome-menus gnome-themes-extra gtk-murrine-engine gtk2-engines glib2-devel kvantum qt5ct qt6ct qt5-qtquickcontrols2 qt5-qtsvg qt6-qtsvg menulibre awf-gtk2 awf-gtk3 awf-gtk4'
#appeditor sddm

gnome_shell_extensions='gnome-shell-extension-gsconnect'

#corectrl mfancontrol lsfg-vk
gaming='antimicrox lutris goverlay gamescope gamemode mangohud vkBasalt fluidsynth openrgb liquidctl coolercontrol' # amdgpu_top lact

# virt-manager gnome-boxes
virtualization='edk2-ovmf genisoimage qemu qemu-img qemu-kvm quickemu socat spice-gtk-tools swtpm swtpm-tools'

extras='bleachbit gnome-system-monitor gnome-software uresourced irqbalance xed'

all_pkgs=(
    "${security[@]}"
    "${shell_setup[@]}"
    "${monitoring_tools[@]}"
    "${disk_file_managers[@]}"
    "${stressers_testers[@]}"
    "${info_fetchers[@]}"
    "${terminal_tools[@]}"
    "${fun_trerminal[@]}"
    "${dev_tools[@]}"
    "${android_tools[@]}"
    "${encryption_backup[@]}"
    "${gui_file_managers[@]}"
    "${theming_compatibility[@]}"
    "${iconsAndFonts[@]}"
    "${gnome_shell_extensions[@]}"
    "${gaming[@]}"
    "${virtualization[@]}"
    "${extras[@]}"
)

log "INFO" "Installing RPM Packages from external sources via links"

# opensnitch
#rpm-ostree install $(curl -s -X GET https://api.github.com/repos/evilsocket/opensnitch/releases/latest | grep -i '"browser_download_url": "[^"]*.noarch.rpm"' | cut -d '"' -f4)

# fastfetch
rpm-ostree install https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm

# watchexec
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/watchexec/watchexec/releases/latest | grep -i '"browser_download_url": "[^"]*-x86_64-unknown-linux-gnu.rpm"' | cut -d'"' -f4)

# vscodium
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)

# amdgpu_top
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/Umio-Yasuno/amdgpu_top/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d '"' -f4)

# lact
rpm-ostree install $(curl -s -X GET https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -i '"browser_download_url": "[^"]*'$(rpm -E %fedora)'.rpm"' | grep -v "headless" | cut -d '"' -f4)

# lsfg-vk
#rpm-ostree install $(curl -s -X GET https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)
log "INFO" "Done."

log "INFO" "Installing RPM Packages"
rpm-ostree install ${all_pkgs[@]}
log "INFO" "Done."

log "INFO" "Disabling copr repos no longer needed"
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra.repo
