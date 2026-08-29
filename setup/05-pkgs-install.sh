#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euo pipefail

log "INFO" "Defining packages..."

# Download remote RPMs to cache
rpm_dl() {
    local rpm_archive="${BUILD_CACHE_DIR}/rpm/${1}.rpm" rpm_url
    { brief_trace; } 2>/dev/null
    if [[ ! -f "${rpm_archive}" ]]; then
        rpm_url="$(latest_ghpkg_url "${2}" "${3}" "${4:-}")"
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
    "zsh"
    "++grex"
    "++yazi"

    # Secure
    #bubblejail
    "++hblock"
    #$(rpm_dl 'opensnitch' 'evilsocket/opensnitch' 'x86_64.rpm$')
    #$(rpm_dl 'opensnitch-noarch' 'evilsocket/opensnitch' 'noarch\.rpm$')

    # Monitoring Tools
    #"htop" "btop"
    "wireshark"
    "++bandwhich"
    "$(rpm_dl 'amdgpu_top' 'Umio-Yasuno/amdgpu_top' 'x86_64\.rpm$')"

    # Disk Operations and Analyze
    #ncdu dua-cli duf
    "fio"

    # Backup, Archive, Encryption and Compression
    ##borgbackup zsync fscrypt
    "rclone"
    "syncthing"
    "archivemount"
    "cryfs"
    "++gocryptfs"

    # Parallelization and Testing
    "s-tui"
    "stress-ng"
    "hyperfine"
    "parallel"
    "memtester"

    # More Terminal Tools
    ##ydotool
    "yt-dlp"
    "kpcli"
#    "$(rpm_dl 'watchexec' 'watchexec/watchexec' 'x86_64-unknown-linux-gnu\.rpm$')"

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
    ##criu criu-amdgpu-plugin ptyxis ghostty lazygit
    "pv" # tool for monitoring the progress of data through a pipeline
    "glow"
    "++uv"
    "neovim"
    #"++llama-cpp"
    "moreutils"
    "ShellCheck"
    "$(rpm_dl 'vscodium' 'VSCodium/vscodium' 'x86_64\.rpm$')"

    # Android Tools
    "++scrcpy"
    "android-tools"

    # waydroid stuff
    "cage"         # Runs a single, maximized application
    "waydroid"
    "wlr-randr"
    "++waydroid_setup"

    # File Manage Stuff
    "nemo"
    "nemo-python"
    "nemo-preview"
    "nemo-emblems"
    "nemo-extensions"
    "nemo-search-helpers"
    "folder-color-switcher-nemo"
    "rom-properties-gtk4" # From terra
    "rom-properties-utils" # From terra

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
    "espeak-ng"
    "solaar-udev" # Udev rules for Logitech wireless receivers
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
    "firewall-config"
    "usbguard-notifier"

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

    # WM tools
    "wmctrl"
    "wl-clipboard"

    # More Terminal Tools
    ##poppler # pdf rendering library
    "axel"
    "aria2"
    "ddcutil"
    "brightnessctl"

    # Dev Tools
    "git"
    "curl"
    "micro"
    "inotify-tools"

    # Android Tools
    "android-tools"

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

    # Gnome Apps and Extensions
    "xed"
#    "menulibre"
    "gnome-tweaks"
    "dconf-editor"
    "gnome-software"
    "gnome-system-monitor"
#    "gnome-shell-extension-hanabi" # from ublue-os/bazzite
    "gnome-shell-extension-common"
    "gnome-shell-extension-gsconnect"

    # Theming Deps
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
    "adwaita-fonts-all"
    "google-noto-fonts-all"
    "fontawesome-fonts-all"

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
    "i2c-tools"
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
    "fish"
    "bash-completion"
    "bash-color-prompt"
    "$(rpm_dl 'fastfetch' 'fastfetch-cli/fastfetch' 'linux-amd64\.rpm$')"
    "starship" # from terra repo
    "fzf"
    "bat"
    "++eza"
    "zoxide"
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
    #dmraid
    "parted"
    "hdparm"
    "nvme-cli"
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
    "zstd"

    # More Terminal Tools
    "jq"
    "yq"
    "gum"
    "just"
    "tree"
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
        # Perform cleanup before any operation
#        dnf5 clean dbcache
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
    *) true ;;
esac

# Process all provided arguments
for arg in "$@"; do
    process_installations "${arg}"
done
