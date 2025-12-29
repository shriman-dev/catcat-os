#!/usr/bin/env bash
set -ouex pipefail
source /usr/lib/catcat/funcvar.sh
set -x

DESKTOP_EXTRAS=(
    # Shell setup
    ##lsd zellij
    "nu"
    "zsh"
    "zoxide"
    "++yazi"
    "++grex"

    # Secure
    "++hblock"

    # Monitoring Tools
    "htop"
    "s-tui"
    "wireshark"
    "++bandwhich"
    #amdgpu_top
    "$(curl -s -X GET https://api.github.com/repos/Umio-Yasuno/amdgpu_top/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d '"' -f4)"

    # Backup, Archive, Encryption and Compression
    ##borgbackup zsync
    "archivemount"
    "cryfs"
    "++gocryptfs"

    # Parallelization and Testing
    "hyperfine"
    "parallel"
    "memtester"

    # More Terminal Tools
    ##ydotool
    "ffmpeg"
    "ffmpegthumbnailer"
    "kpcli"
    #watchexec
    "$(curl -s -X GET https://api.github.com/repos/watchexec/watchexec/releases/latest | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.rpm"' | cut -d'"' -f4)"

    # Dev Tools
    ##criu criu-amdgpu-plugin ptyxis ghostty lazygit
    "++llama_cpp"

    # Rocm lib
    #rocm-hip
    #rocm-opencl
    #rocm-clinfo
    #rocm-smi

    # File Manage Stuff
    "nemo"
    "nemo-emblems"
    "nemo-extensions"
    "nemo-preview"
    "nemo-python"

    # Extra Gnome Apps
    "awf-gtk2"
    "awf-gtk3"
    "awf-gtk4"

    # Virtualization
    ##virt-manager gnome-boxes
    "qemu"
    "qemu-img"
    "qemu-kvm"
    "quickemu"
    "edk2-ovmf"
    "edk2-tools"
    "genisoimage"
    "socat"
    "spice-gtk-tools"
    "swtpm"
    "swtpm-tools"
    "++ls_iommu"

    # Gaming Stuff
    ##coolercontrol mfancontrol liquidctl lsfg-vk
    ##fluidsynth gamemode gamescope goverlay lutris mangohud vkBasalt
    "antimicrox"
    "openrgb"
    "openrgb-udev-rules"
    #lsfg-vk
    #$(curl -s -X GET https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)

    # Performance Tuning
    ##corectrl
    "uresourced"
    "irqbalance"
    #lact
    #"$(curl -s -X GET https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -i '"browser_download_url": "[^"]*'$(rpm -E %fedora)'.rpm"' | grep -v "headless" | cut -d '"' -f4)"

    # Extras
    "++extras"
)

DESKTOP_COMMON=(
    # Secure
    "firewall-config"
    "usbguard-notifier"
    #opensnitch
    #$(curl -s -X GET https://api.github.com/repos/evilsocket/opensnitch/releases/latest | grep -i '"browser_download_url": "[^"]*.noarch.rpm"' | cut -d '"' -f4)

    # Monitoring Tools
    "powertop"
    "powerstat"
    "lm_sensors"

    # Info Helper
    ##hwinfo
    "inxi"
    "tealdeer"

    # Disk Operations and Analyze
    "gparted"
    "exfatprogs"
    "gnome-disk-utility"

    # Backup, Archive, Encryption and Compression
    "rclone"
    "syncthing"

    # WM tools
    #wlr-randr
    "wmctrl"
    "wl-clipboard"
    "gnome-randr-rust" # from bazzite-org/bazzite

    # More Terminal Tools
    ##poppler # pdf rendering library
    "aria2"
    "ddcutil"
    "brightnessctl"

    # Fun Terminal Tools
    "sl"
    "neo"
    "cava"
    "oneko"
    "cowsay"
    "cbonsai"
    "cmatrix"
    "asciinema"
    "++pipes_sh"
    "fortune-mod"
    "asciiquarium"
    "++ascii_image_converter"

    # Dev Tools
    "git"
    "glow"
    "micro"
    "neovim"
    "python3-pip"
    "inotify-tools"
    #vscodium
    "$(curl -s -X GET https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep -i '"browser_download_url": "[^"]*.x86_64.rpm"' | cut -d'"' -f4)"

    # Android Tools
    "++scrcpy"
    "android-tools"

    # waydroid stuff
    "cage" # runs a single, maximized application
    "waydroid"
    "wlr-randr"
    "++waydroid_setup"

    # Containers
    "distrobox"
    "podman"
    "udica"

    # File Manage Stuff
    "sushi"
    "nautilus-python"
    "nautilus-gsconnect"
    "nautilus-extensions"
    "rom-properties-gtk3" # from bazzite-org/rom-properties

    # Gnome Apps and Extensions
    "xed"
    "menulibre"
    "gnome-tweaks"
    "dconf-editor"
    "gnome-software"
    "gnome-system-monitor"
    "gnome-shell-extension-hanabi" # from bazzite-org/bazzite
    "gnome-shell-extension-common"
    "gnome-shell-extension-gsconnect"

    # Themeing and Extension Deps
    "adwaita-fonts-all"
    "adwaita-gtk2-theme"
    "gnome-themes-extra"
    "gtk-murrine-engine"
    "gtk2-engines"
    "sassc"
    "qt5ct"
    "qt6ct"
    "kvantum"
    "kvantum-qt5"
    "gnome-menus"
    "glib2-devel"
    "libgtop2"
    "libappindicator-gtk3"

    # Yubikey Deps
    "pam-u2f"
    "pam_yubico"
    "pamu2fcfg"
    "yubikey-manager"

    # Needed Deps
    "yad"
    "zenity"
    "i2c-tools"
    "alsa-firmware"
    "grub2-tools-extra"
    "google-noto-fonts-all"
)

COMMON=(
    # Shell setup
    "fish"
    #fastfetch
    "$(curl -s -X GET https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep -i '"browser_download_url": "[^"]*linux-amd64.rpm"' | cut -d'"' -f4)"
    "starship" # from terra repo
    "fzf"
    "bat"
    "++eza"
    "ripgrep"
    "fd-find"
    "tmux"

    # Secure
    "firewalld"
    "usbguard"
    "setools-console"

    # Monitoring Tools
    "btop"
    "procs"
    "nethogs"
    "tcpdump"
    "traceroute"

    # Info Helper
    "which"
    "lshw"
    "smartmontools"

    # Disk Operations and Analyze
    #dmraid ncdu dua-cli
    "parted"
    "hdparm"
    "nvme-cli"
    "fio"
    "gdu"
    "++btdu"
    "compsize"

    # Backup, Archive. Encryption and Compression
    "++buttersnap"
    "rsync"
    "unrar"
    "unzip"
    "p7zip"
    "p7zip-plugins"
    "fscrypt"
    "zstd"

    # More Terminal Tools
    "jq"
    "gum"

    # Performance Tuning
    "tuned"

    # Exrtas
    "++ujust_setup"

    # Needed Deps
    #cosign
    "bootc"
    "gettext"
    "openssl"
    "lsb_release"
    "sbsigntools" # tools to add signatures to efi binaries and drivers
    "wireguard-tools"
    "fwupd"
    "fwupd-plugin-flashrom"
    "fwupd-plugin-modem-manager"
    "fwupd-plugin-uefi-capsule-data"
)

#log "INFO" "Performing updates"
#rpm -q dnf5-plugins || rpm-ostree install dnf5 dnf5-plugins
#dnf5 upgrade --refresh --assumeyes
#log "INFO" "Done."

log "INFO" "Adding extra RPM repos"
#dnf5 -y install \
#        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
#        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
dnf5 -y copr enable bazzite-org/bazzite
dnf5 -y copr enable bazzite-org/rom-properties
if [[ -f /etc/yum.repos.d/terra.repo ]]; then
    sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/terra.repo
    sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/terra-extras.repo
else
    dnf5 -y install --nogpgcheck --repofrompath \
            'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}
fi

log "INFO" "Installing RPM Packages"
if [[ "${IMAGE_NAME}" =~ "-sv" ]]; then
    dnf5 -y install \
        $(printf '%s\n' "${COMMON[@]}" | grep -v "^++")
elif [[ "${IMAGE_NAME}" =~ "-mi" ]]; then
    dnf5 -y install \
        $(printf '%s\n' "${COMMON[@]}" | grep -v "^++")
    dnf5 -y --setopt=install_weak_deps=False install \
        $(printf '%s\n' "${DESKTOP_COMMON[@]}" | grep -v "^++")
else
    dnf5 -y --setopt=disable_excludes=* install mesa-demos # need for quickemu
    dnf5 -y install \
        $(printf '%s\n' "${COMMON[@]} ${DESKTOP_COMMON[@]} ${DESKTOP_EXTRAS[@]}" | grep -v "^++")
fi
log "INFO" "Done."


log "INFO" "Disabling repos no longer needed"
sed -i 's|enabled_metadata=.*|enabled_metadata=0|g' /etc/yum.repos.d/terra*.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra-extras.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra-mesa.repo || true
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo || true
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo || true
dnf5 -y copr disable bazzite-org/bazzite || true
dnf5 -y copr disable bazzite-org/bazzite-multilib || true
dnf5 -y copr disable bazzite-org/rom-properties || true
dnf5 -y copr disable bazzite-org/obs-vkcapture || true
dnf5 -y copr disable hhd-dev/hhd || true
dnf5 -y copr disable ublue-os/staging || true
dnf5 -y copr disable ublue-os/packages || true
#dnf5 -y copr disable kylegospo/unl0kr || true
#dnf5 -y copr disable atim/starship || true
#dnf5 -y copr disable zeno/scrcpy || true
#dnf5 -y copr disable scottames/ghostty || true
#dnf5 -y copr disable atim/lazygit || true
log "INFO" "Done."


# Remove things that doesn't work well with NVIDIA
if [[ ${IMAGE_NAME} =~ "-nv" ]]; then
    log "INFO" "Removeing packages unneeded on NVIDIA image"
    #nvidia-gpu-firmware
    dnf5 -y remove \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi
    log "INFO" "Done."
fi


log "INFO" "Installing External Packages"
if [[ "${IMAGE_NAME}" =~ "-sv" ]]; then
    ${SETUP_DIR}/06-extra-pkgs.sh \
        $(printf '%s\n' "${COMMON[@]}" | grep "^++" | sed 's|++||')
elif [[ "${IMAGE_NAME}" =~ "-mi" ]]; then
    ${SETUP_DIR}/06-extra-pkgs.sh \
        $(printf '%s\n' "${COMMON[@]} ${DESKTOP_COMMON[@]}" | grep "^++" | sed 's|++||')
else
    ${SETUP_DIR}/06-extra-pkgs.sh \
        $(printf '%s\n' "${COMMON[@]} ${DESKTOP_COMMON[@]} ${DESKTOP_EXTRAS[@]}" | grep "^++" | sed 's|++||')
fi
log "INFO" "All Done."
