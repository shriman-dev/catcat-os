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
    "kpcli"
#    "$(rpm_dl 'watchexec' 'watchexec/watchexec' 'x86_64-unknown-linux-gnu\.rpm$')"

    # Dev Tools
    ##criu criu-amdgpu-plugin ptyxis ghostty lazygit
    #"++llama-cpp"

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
    "libadwaita"
    "gtk4-devel-tools"
    "gtk3-devel"

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
    "podman-machine"
    "++ls-iommu"

    # Gaming packages
    ##coolercontrol mfancontrol liquidctl lsfg-vk
    ##fluidsynth gamemode gamescope goverlay lutris mangohud vkBasalt
    "input-remapper"
    "antimicrox"

    # Gaming Deps
    "openrgb"
    "openrgb-udev-rules"
    "libratbag-ratbagd" # DBus daemon to access programmable input devices, mainly gaming mice
    #"$(rpm_dl 'lact' 'ilya-zlobintsev/LACT' "x86_64\.fedora-$(rpm -E %fedora)\.rpm$" 'headless')"
    #"$(rpm_dl 'lsfg-vk' 'PancakeTAS/lsfg-vk' 'x86_64\.rpm$')"

    # Extras deps
    "++extras"
#    "rocm"
#    "rocm-core"
#    "rocm-hip"
#    "rocm-opencl"
#    "rocminfo"
#    "rocm-clinfo"
#    "rocm-smi"
#    "hipblas"
#    "hipblaslt"
)

DESKTOP_COMMON=(
    # Secure
    #bubblejail
    "firewall-config"
    "usbguard-notifier"
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
    "mediainfo"

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
    "cage"         # Runs a single, maximized application
    "waydroid"
    "wlr-randr"
    "++waydroid_setup"

    # Containers
    "distrobox"
    "podman-compose"
    "podman"
    "buildah"
    "udica"

    # File Manage Stuff
    "sushi"
    "nautilus-python"
    "nautilus-gsconnect"
    "nautilus-extensions"
    "rom-properties-gtk4" # From terra
    "rom-properties-utils" # From terra

    # Gnome Apps and Extensions
    "xed"
    #"menulibre"
    "gnome-tweaks"
    "dconf-editor"
    "gnome-software"
    "gnome-system-monitor"
#    "gnome-shell-extension-hanabi" # from ublue-os/bazzite
    "gnome-shell-extension-common"
    "gnome-shell-extension-gsconnect"

    # Theming Deps
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
    "libappindicator-gtk3"
    "google-noto-fonts-all"

    # Yubikey Deps
    "pam-u2f"
    "pam_yubico"
    "pamu2fcfg"
    "yubikey-manager"

    # Needed Deps
    "yad"
    "zenity"
    "libmtp"
    "gvfs-mtp"
    "gvfs-fuse"
    "espeak-ng"
    "i2c-tools"
    "solaar-udev" # Udev rules for Logitech wireless receivers
    "steam-devices"
    "grub2-tools-extra"
    "libcamera"
    "libcamera-ipa"
    "libcamera-tools"
    "libcamera-gstreamer"
    "libimobiledevice-utils"
    "pipewire-plugin-libcamera"
)

COMMON=(
    # Shell setup
    "zsh"
    "fish"
    "bash-completion"
    "bash-color-prompt"
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
    "sbsigntools" # Tools to add signatures to efi binaries and drivers
    "setools-console"
    "++dnscrypt-proxy"

    # Monitoring Tools
    #"btop"
    "procs"
    "nethogs"
    "tcpdump"
    "traceroute"
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

    # Networking
    "iwd"
    "openssl"
    "wireguard-tools"

    # Firmware
    "fwupd"
    "fwupd-efi"
    "fwupd-plugin-flashrom"
    "fwupd-plugin-modem-manager"
    "fwupd-plugin-uefi-capsule-data"

    # Exrtas
    "++ucat_setup"

    # Needed Deps
    #cosign
    "apr" # Apache Portable Runtime C library
    "apr-util"
    #"greenboot" # Automate rollbacks to the last known working state
    "newt" # Library for windows and widgets in terminal
    "bootc"
    "gettext" # Libraries for localized translated messages
    "lsb_release" # os-release
    "dnf5-plugins"
)

process_installations() {
    case "${1}" in
        kernel)
            kernel_add
            ;;
        common)
            pkgs_install "${1}" "${COMMON[@]}"
            ;;
        hwaccel)
            pkgs_hwaccel
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
            pkgs_hwaccel
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
