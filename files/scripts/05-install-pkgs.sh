#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Defining packages"

DESKTOP_EXTRAS=(
    # Shell setup
    ##lsd zellij
    "nu"
    "++grex"

    # Secure
    "++hblock"

    # Monitoring Tools
    #"htop"
    "s-tui"
    "stress-ng"
    "wireshark"
    "++bandwhich"
    #amdgpu_top
    "$(latest_ghpkg_url 'Umio-Yasuno/amdgpu_top' 'x86_64\.rpm$')"

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
    "$(latest_ghpkg_url 'watchexec/watchexec' 'x86_64-unknown-linux-gnu\.rpm$')"

    # Dev Tools
    ##criu criu-amdgpu-plugin ptyxis ghostty lazygit
    "buildah"
    "++llama-cpp"

    # Rocm lib
    #rocm-hip
    #rocm-opencl
    #rocm-clinfo
    #rocm-smi

    # File Manage Stuff
    "nemo"
    "nemo-python"
    "nemo-preview"
    "nemo-emblems"
    "nemo-extensions"
    "nemo-search-helpers"
    "folder-color-switcher-nemo"

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
    "++ls-iommu"

    # Gaming Stuff
    ##coolercontrol mfancontrol liquidctl lsfg-vk
    ##fluidsynth gamemode gamescope goverlay lutris mangohud vkBasalt
    "antimicrox"
    "openrgb"
    "openrgb-udev-rules"
    #lsfg-vk
    #$(latest_ghpkg_url 'PancakeTAS/lsfg-vk' 'x86_64\.rpm$')

    # Performance Tuning
    ##corectrl
    "uresourced"
    "irqbalance"
    #lact
    #"$(latest_ghpkg_url 'ilya-zlobintsev/LACT' "x86_64\.fedora-$(rpm -E %fedora)\.rpm$" 'headless')"

    # Extras
    "rocm-hip"
    "rocm-opencl"
    "rocm-clinfo"
    "rocm-smi"
    "++extras"
)

DESKTOP_COMMON=(
    # Secure
    #bubblejail
    "firewall-config"
    "usbguard-notifier"
    #opensnitch
    #$(latest_ghpkg_url 'evilsocket/opensnitch' 'x86_64.rpm$')
    #$(latest_ghpkg_url 'evilsocket/opensnitch' 'noarch\.rpm$')

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
    "axel"
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
    "++pipes-sh"
    "fortune-mod"
    "asciiquarium"
    "++ascii-image-converter"

    # Dev Tools
    "git"
    "glow"
    "micro"
    "neovim"
    "python3-pip"
    "inotify-tools"
    #vscodium
    "$(latest_ghpkg_url 'VSCodium/vscodium' 'x86_64\.rpm$')"

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
    "podman-compose"
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
    "gnome-software-rpm-ostree"
    "gnome-shell-extension-hanabi" # from bazzite-org/bazzite
    "gnome-shell-extension-common"
    "gnome-shell-extension-gsconnect"

    # Themeing Deps
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
    "ffmpegthumbnailer"
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
    "++wldrivers"
    "alsa-firmware"
    #"pipewire-libs-extra"
    "steam-devices"
    "grub2-tools-extra"
    "google-noto-fonts-all"
)

COMMON=(
    # Shell setup
    "zsh"
    "fish"
    #fastfetch
    "$(latest_ghpkg_url 'fastfetch-cli/fastfetch' 'linux-amd64\.rpm$')"
    "starship" # from terra repo
    "fzf"
    "bat"
    "++eza"
    "zoxide"
    "++yazi"
    "ripgrep"
    "fd-find"
    "tmux"

    # Secure
    "firewalld"
    "usbguard"
    "setools-console"
    "++dnscrypt-proxy"

    # Monitoring Tools
    #"btop"
    "procs"
    "bottom" # from terra repo
    "nethogs"
    "tcpdump"
    "traceroute"
    #bottom
    "$(latest_ghpkg_url 'ClementTsang/bottom' 'x86_64\.rpm$' 'musl')"

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
    "7zip"
    "7zip-standalone-all"
    "fscrypt"
    "zstd"

    # More Terminal Tools
    "jq"
    "pv" # tool for monitoring the progress of data through a pipeline
    "gum"
    "just"
    "kmscon"
    "kmscon-gl"

    # Performance Tuning
    "tuned"

    # Exrtas
    "++ujust_setup"

    # Needed Deps
    #cosign
    "bootc"
    "gettext" # libraries for localized translated messages
    "openssl"
    "lsb_release" # os-release
    "dnf5-plugins"
    "sbsigntools" # tools to add signatures to efi binaries and drivers
    "wireguard-tools"
    "kernel-headers"
    "kernel-devel-matched"
    "fwupd"
    "fwupd-efi"
    "fwupd-plugin-flashrom"
    "fwupd-plugin-modem-manager"
    "fwupd-plugin-uefi-capsule-data"
)

#log "INFO" "Performing updates"
#rpm -q dnf5-plugins || rpm-ostree install dnf5 dnf5-plugins
#dnf5 upgrade --refresh --assumeyes
#log "INFO" "Updates complete"

log "INFO" "Adding extra RPM repos"
COPR_LIST=(
    "bazzite-org/bazzite"
#    "bazzite-org/bazzite-multilib"
    "bazzite-org/rom-properties"
#    "bazzite-org/obs-vkcapture"
#    "hhd-dev/hhd"
#    "ublue-os/staging"
#    "ublue-os/packages"
#    "kylegospo/unl0kr"
#    "atim/starship"
#    "zeno/scrcpy"
#    "scottames/ghostty"
#    "atim/lazygit"
)

for copr in "${COPR_LIST[@]}"; do
    dnf5 -y copr enable "${copr}"
done

#dnf5 -y install \
#        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
#        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
if [[ -f /etc/yum.repos.d/terra.repo ]]; then
    sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/terra.repo
    sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/terra-extras.repo
else
    #--setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
                    terra-release{,-extras}
fi
log "INFO" "Added extra repos"


log "INFO" "Installing RPM Packages"

dnf5 -y --setopt=install_weak_deps=True install \
        $(printf '%s\n' "${COMMON[@]}" | grep -v "^++")

[[ ! "${IMAGE_NAME}" =~ "-sv" ]] &&
    dnf5 -y install \
        $(printf '%s\n' "${DESKTOP_COMMON[@]}" | grep -v "^++")

if [[ ! "${IMAGE_NAME}" =~ (-mi|-sv) ]]; then
    dnf5 -y --setopt=disable_excludes=* install mesa-demos # dep of quickemu
    dnf5 -y install \
        $(printf '%s\n' "${DESKTOP_EXTRAS[@]}" | grep -v "^++")
fi

log "INFO" "Packages installed successfully"


log "INFO" "Disabling repos no longer needed"
sed -i 's|enabled_metadata=.*|enabled_metadata=0|g' /etc/yum.repos.d/terra*.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra-extras.repo
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/terra-mesa.repo || true
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo || true
sed -i 's|enabled=1|enabled=0|g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo || true
for copr in "${COPR_LIST[@]}"; do
    dnf5 -y copr disable "${copr}"
done
log "INFO" "Disabled unneeded repos"


log "INFO" "Installing External Packages"
exec_script "${BUILD_SETUP_DIR}"/06-extra-pkgs.sh \
        $(printf '%s\n' "${COMMON[@]}" | sed -n 's|++||gp')

[[ ! "${IMAGE_NAME}" =~ "-sv" ]] &&
    exec_script "${BUILD_SETUP_DIR}"/06-extra-pkgs.sh \
        $(printf '%s\n' "${DESKTOP_COMMON[@]}" | sed -n 's|++||gp')

if [[ ! "${IMAGE_NAME}" =~ (-mi|-sv) ]]; then
    exec_script "${BUILD_SETUP_DIR}"/06-extra-pkgs.sh \
        $(printf '%s\n' "${DESKTOP_EXTRAS[@]}" | sed -n 's|++||gp')
fi

log "INFO" "External packages installed successfully"
