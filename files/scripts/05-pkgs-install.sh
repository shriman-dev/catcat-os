#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euo pipefail

log "INFO" "Defining packages..."

# Download remote RPMs to cache
rpm_dl() {
    local rpm_archive="${BUILD_CACHE_DIR}/rpm/${1}.rpm"
    { brief_trace; } 2>/dev/null
    if [[ ! -f "${rpm_archive}" ]]; then
        local rpm_url="$(latest_ghpkg_url "${2}" "${3}" "${4:-}")"
        curl_get "${rpm_archive}" "${rpm_url}"
        echo "${rpm_archive}"
    else
        echo "${rpm_archive}"
    fi
    { brief_trace; } 2>/dev/null
}

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
    "$(rpm_dl 'amdgpu_top' 'Umio-Yasuno/amdgpu_top' 'x86_64\.rpm$')"

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
    "yt-dlp"
    "ffmpeg"
    "ffmpegthumbnailer"
    "kpcli"
    #watchexec
    "$(rpm_dl 'watchexec' 'watchexec/watchexec' 'x86_64-unknown-linux-gnu\.rpm$')"

    # Dev Tools
    ##criu criu-amdgpu-plugin ptyxis ghostty lazygit
    "buildah"
    #"++llama-cpp"

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
    "input-remapper"
    "antimicrox"
    "openrgb"
    "openrgb-udev-rules"
    #lsfg-vk
    #$(rpm_dl 'lsfg-vk' 'PancakeTAS/lsfg-vk' 'x86_64\.rpm$')

    # Performance Tuning
    ##corectrl
    "uresourced"
    #"irqbalance"
    #lact
    #"$(rpm_dl 'lact' 'ilya-zlobintsev/LACT' "x86_64\.fedora-$(rpm -E %fedora)\.rpm$" 'headless')"

    # Extras deps
#    "rocm"
#    "rocm-core"
#    "rocm-hip"
#    "rocm-opencl"
#    "rocminfo"
#    "rocm-clinfo"
#    "rocm-smi"
#    "hipblas"
#    "hipblaslt"
    "++extras"
)

DESKTOP_COMMON=(
    # Secure
    #bubblejail
    "firewall-config"
    "usbguard-notifier"
    #opensnitch
    #$(rpm_dl 'opensnitch' 'evilsocket/opensnitch' 'x86_64.rpm$')
    #$(rpm_dl 'opensnitch-noarch' 'evilsocket/opensnitch' 'noarch\.rpm$')

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
    "fortune-mod"
    "asciiquarium"
    "++pipes-sh"
    "++chess-tui"
    "++ascii-image-converter"

    # Dev Tools
    "git"
    "glow"
    "++uv"
    "micro"
    "neovim"
    "inotify-tools"
    #vscodium
    "$(rpm_dl 'vscodium' 'VSCodium/vscodium' 'x86_64\.rpm$')"

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
#    "rom-properties-gtk4" # from ublue-os/rom-properties

    # Gnome Apps and Extensions
    "xed"
    #"menulibre"
    "gnome-tweaks"
    "dconf-editor"
    "gnome-software"
    "gnome-system-monitor"
    "gnome-software-rpm-ostree"
#    "gnome-shell-extension-hanabi" # from ublue-os/bazzite
    "gnome-shell-extension-common"
    "gnome-shell-extension-gsconnect"

    # Themeing Deps
    "adwaita-fonts-all"
    #"adwaita-gtk2-theme"
    #"gnome-themes-extra"
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
    "espeak-ng"
    "i2c-tools"
    #"++wldrivers"
    "alsa-firmware"
    #"pipewire-libs-extra"
    "solaar-udev" # udev rules for Logitech wireless receivers
    "steam-devices"
    "grub2-tools-extra"
    "google-noto-fonts-all"
    "libcamera-tools"
    "libcamera-gstreamer"
    "libimobiledevice-utils"
)

COMMON=(
    # Shell setup
    "zsh"
    "fish"
    #fastfetch
    "$(rpm_dl 'fastfetch' 'fastfetch-cli/fastfetch' 'linux-amd64\.rpm$')"
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
    "nethogs"
    "tcpdump"
    "traceroute"
    #bottom
    "$(rpm_dl 'bottom' 'ClementTsang/bottom' 'x86_64\.rpm$' 'musl')"

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
    "++ucat_setup"

    # Needed Deps
    #cosign
    "iwd"
    "newt" # library for windows and widgets in terminal
    "bootc"
    "gettext" # libraries for localized translated messages
    "openssl"
    "lsb_release" # os-release
    "dnf5-plugins"
    "sbsigntools" # tools to add signatures to efi binaries and drivers
    "wireguard-tools"
    "fwupd"
    "fwupd-efi"
    "fwupd-plugin-flashrom"
    "fwupd-plugin-modem-manager"
    "fwupd-plugin-uefi-capsule-data"
)

kernel_add() {
    ( set -x; "${BUILD_SETUP_DIR}"/script_lib/pkgs-kernel.sh add )
}

process_installations() {
    case "${1}" in
        kernel)
            kernel_add
            ;;
        common)
            pkgs_install "${1}" "${COMMON[@]}"
            ;;
        desktop_comm)
            pkgs_install "${1}" "${DESKTOP_COMMON[@]}"
            ;;
        desktop_extra)
            pkgs_install "${1}" "${DESKTOP_EXTRAS[@]}"
            ;;
        desktop)
            pkgs_install "${1}" "${DESKTOP_COMMON[@]}" "${DESKTOP_EXTRAS[@]}"
            ;;
        all)
            kernel_add
            pkgs_install "${1}" "${COMMON[@]}" "${DESKTOP_COMMON[@]}" "${DESKTOP_EXTRAS[@]}"
            ;;
        *) die "Unknown argument: ${1}";;
    esac
}

case "${1}" in
    batch-start)
        rpm_repos enable
        shift
        ;;
    batch-end)
        trap "rpm_repos disable" EXIT
        shift
        ;;
    no-batch)
        rpm_repos enable
        trap "rpm_repos disable" EXIT
        shift
        ;;
esac

# Process all provided arguments
for arg in "$@"; do
    process_installations "${arg}"
done
