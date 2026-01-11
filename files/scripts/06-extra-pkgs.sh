#!/usr/bin/env bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

TMP_DIR="/tmp/extra_pkgs"

starship() {
    local pkg_repo="https://api.github.com/repos/starship/starship"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/starship" "/usr/bin"/
    chmod -v +x /usr/bin/starship
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

eza() {
    local pkg_repo="https://github.com/eza-community/eza"
    local latest_pkg_url="${pkg_repo}/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/eza" /usr/bin/
    chmod -v +x /usr/bin/eza
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

grex() {
    local pkg_repo="https://api.github.com/repos/pemistahl/grex"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-musl.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/grex" "/usr/bin"/
    chmod -v +x /usr/bin/grex
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

bandwhich() {
    local pkg_repo="https://api.github.com/repos/imsnif/bandwhich"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/bandwhich" "/usr/bin"/
    chmod -v +x /usr/bin/bandwhich
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

gocryptfs() {
    local pkg_repo="https://api.github.com/repos/rfjakob/gocryptfs"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux-static_amd64.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/gocryptfs" "/usr/bin"/
    chmod -v +x /usr/bin/gocryptfs
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

ls_iommu() {
    local pkg_repo="https://api.github.com/repos/HikariKnight/ls-iommu"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*Linux_x86_64.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract/ls-iommu" "/usr/bin"/
    chmod -v +x /usr/bin/ls-iommu
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

yazi() {
    local pkg_repo="https://github.com/sxyazi/yazi"
    local pkg_repo_raw="https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main"
    local latest_pkg_url="${pkg_repo}/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    mkdir -vp "${pkg_archive}.extract"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"
    curl -Lo /usr/share/applications/yazi.desktop "${pkg_repo_raw}/assets/yazi.desktop"
    curl -Lo /usr/share/icons/yazi.png "${pkg_repo_raw}/assets/logo.png"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    cp -dvf "${pkg_archive}.extract"/yazi*/{ya,yazi} /usr/bin/
    chmod -v +x /usr/bin/{ya,yazi}
    cp -dvf "${pkg_archive}.extract"/yazi*/completions/{ya,yazi}.bash \
                    /usr/share/bash-completion/completions/
    cp -dvf "${pkg_archive}.extract"/yazi*/completions/{ya,yazi}.fish \
                    /usr/share/fish/completions/
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

hblock() {
    local pkg_repo_raw="https://raw.githubusercontent.com/hectorm/hblock/refs/heads/master"
    local dns_blocklist_repo="https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main"
    local hblock_confd="/etc/hblock"

    curl -Lo "/usr/bin/hblock" "${pkg_repo_raw}/hblock"
    chmod -v +x "/usr/bin/hblock"

    # Get hblock config
    log "INFO" "Getting hblock configuration"
    mkdir -vp "${hblock_confd}"
    curl -Lo "${hblock_confd}/sources.list" "${dns_blocklist_repo}/hblock/sources.list"
    curl -Lo "${hblock_confd}/deny.list" "${dns_blocklist_repo}/hblock/deny.list"
    curl -Lo "${hblock_confd}/allow.list" "${dns_blocklist_repo}/hblock/allow.list"
}

buttersnap() {
    local pkg_repo_raw="https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main"

    curl -Lo "/usr/bin/buttersnap.sh" "${pkg_repo_raw}/buttersnap.sh"
    curl -Lo "/usr/bin/buttercopy.sh" "${pkg_repo_raw}/buttercopy.sh"
    chmod -v +x "/usr/bin"/{buttersnap.sh,buttercopy.sh}
}

btdu() {
    local pkg_repo="https://github.com/CyberShadow/btdu"

    curl -Lo "/usr/bin/btdu" "${pkg_repo}/releases/latest/download/btdu-static-x86_64"

    chmod -v +x "/usr/bin/btdu"
}

scrcpy() {
    local pkg_repo="https://api.github.com/repos/Genymobile/scrcpy"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux-x86_64-.*.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"
    local usrlibexec_pkg="/usr/libexec/scrcpy"

    mkdir -vp "${pkg_archive}.extract" "${usrlibexec_pkg}"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"
    cp -dvf "${pkg_archive}.extract"/*/* "${usrlibexec_pkg}"/
    ln -svf /usr/bin/adb "${usrlibexec_pkg}/adb"
    ln -svf "${usrlibexec_pkg}/scrcpy" /usr/bin/scrcpy
    chmod -v +x "${usrlibexec_pkg}/scrcpy"
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

llama_cpp_vk() {
    local pkg_repo="https://api.github.com/repos/ggml-org/llama.cpp"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*ubuntu-vulkan-x64.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"
    local usrlibexec_pkg="/usr/libexec/llama_cpp_vk"

    mkdir -vp "${pkg_archive}.extract" "${usrlibexec_pkg}"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    mv -v "${pkg_archive}.extract"/llama*/* "${usrlibexec_pkg}"/
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

llama_cpp() {
    local pkg_repo="https://api.github.com/repos/ggml-org/llama.cpp"
    local latest_pkg_url="$(curl -s -X GET "${pkg_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*ubuntu-x64.tar.gz"' | cut -d '"' -f4)"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"
    local usrlibexec_pkg="/usr/libexec/llama_cpp"

    mkdir -vp "${pkg_archive}.extract" "${usrlibexec_pkg}"
    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    mv -v "${pkg_archive}.extract"/llama*/* "${usrlibexec_pkg}"/
    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

pipes_sh() {
    local pkg_repo_raw="https://raw.githubusercontent.com/pipeseroni/pipes.sh/refs/heads/master"

#    curl -Lo "/usr/bin/pipes.sh" "${pkg_repo_raw}/pipes.sh"
    chmod -v +x "/usr/bin/pipes.sh"
}

ascii_image_converter() {
    local pkg_repo="https://github.com/TheZoraiz/ascii-image-converter"
    local latest_pkg_url="${pkg_repo}/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz"
    local pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

#    mkdir -vp "${pkg_archive}.extract"
#    curl -Lo "${pkg_archive}" "${latest_pkg_url}"

#    unarchive "${pkg_archive}" "${pkg_archive}.extract"
#    cp -dvf "${pkg_archive}.extract"/*/ascii-image-converter "/usr/bin"/
    chmod -v +x /usr/bin/ascii-image-converter
#    rm -rf "${pkg_archive}" "${pkg_archive}.extract"
}

ujust_setup() {
    local just_repo="https://api.github.com/repos/casey/just"
    local latest_just_url="$(curl -s -X GET "${just_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-musl.tar.gz"' | cut -d '"' -f4)"
    local just_tar="${TMP_DIR}/$(basename ${latest_just_url})"
    local ublue_repo="https://raw.githubusercontent.com/ublue-os/packages/refs/heads/main/packages"
    local bazzite_repo="https://raw.githubusercontent.com/ublue-os/bazzite/refs/heads/main/system_files/desktop/shared/usr/share/ublue-os/just"
    local import_file="/usr/share/ublue-os/justfile"
    local justfile_dir="$(dirname ${BUILD_SETUP_DIR})/justfiles"

    mkdir -vp /usr/share/ublue-os/{just,lib-ujust}
    rpm -q just || {
        log "INFO" "Installing just"
        mkdir -vp "${just_tar}.extract"

        curl -Lo "${just_tar}" "${latest_just_url}"

        unarchive "${just_tar}" "${just_tar}.extract"
        cp -dvf "${just_tar}.extract/just.1" "/usr/share/man/man1/just.1"
        cp -dvf "${just_tar}.extract/just" "/usr/bin"/
        chmod -v +x /usr/bin/just
        rm -rf "${just_tar}" "${just_tar}.extract"
        log "INFO" "Done."
    }

    [[ ! -x "/usr/bin/ujust" ]] && {
        log "INFO" "Installing ujust and ugum"
        curl -Lo "/usr/bin/ujust" "${ublue_repo}/ublue-os-just/src/ujust"
        curl -Lo "/usr/bin/ugum" "${ublue_repo}/ublue-os-just/src/ugum"
        chmod -v +x /usr/bin/{ujust,ugum}
        log "INFO" "Done."
    }

    # Needed files for luks tpm2 autounlock recipe
    [[ ! -f "/usr/libexec/luks-enable-tpm2-autounlock" ]] && {
        mkdir -vp /usr/lib/dracut/dracut.conf.d
        curl -Lo "/usr/lib/dracut/dracut.conf.d/90-ublue-luks.conf" \
                    "${ublue_repo}/ublue-os-luks/src/90-ublue-luks.conf"
        curl -Lo "/usr/libexec/luks-enable-tpm2-autounlock" \
                    "${ublue_repo}/ublue-os-luks/src/luks-enable-tpm2-autounlock"
        curl -Lo "/usr/libexec/luks-disable-tpm2-autounlock" \
                    "${ublue_repo}/ublue-os-luks/src/luks-disable-tpm2-autounlock"
    }

    # Waydroid setup recipe
    rpm -q waydroid && [[ ! -f "${justfile_dir}/82-bazzite-waydroid.just" ]] && {
        curl -Lo "${justfile_dir}/82-bazzite-waydroid.just" "${bazzite_repo}/82-bazzite-waydroid.just"
        sed -i '/waydroid-container-restart.desktop/d' "${justfile_dir}/82-bazzite-waydroid.just"
        sed -i 's|source /usr/lib/ujust/ujust.sh|source /usr/lib/catcat/funcvar.sh|' \
                "${justfile_dir}/82-bazzite-waydroid.just"
    }

    # Organize ujust
    log "INFO" "Categorizing justfiles"
#    sed '/^\[group/d' /usr/share/ublue-os/just/*.just
    sed -i -E '/^configure-broadcom-wl/i [group\("hardware"\)]' \
                            /usr/share/ublue-os/just/50-akmods.just || true
    sed -i -E '/^enroll-secure-boot-key/i [group\("utilities"\)]' \
                            /usr/share/ublue-os/just/00-default.just || true
    sed -i -E '/^(toggle-nvk|configure-(nvidia|nvidia-optimus))/i [group\("nvidia"\)]' \
                            /usr/share/ublue-os/just/40-nvidia.just || true
    sed -i -E '/^install-resolve/i [group\("apps"\)]' \
                            /usr/share/ublue-os/just/30-distrobox.just || true
    sed -i 's|^toggle-user-motd|_toggle-user-motd|' \
                            /usr/share/ublue-os/just/00-default.just || true
    sed -i 's|^changelogs-testing|_changelogs-testing|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^distrobox-assemble|_distrobox-assemble|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^distrobox-new|_distrobox-new|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^setup-distrobox-app|_setup-distrobox-app|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^install-coolercontrol|_install-coolercontrol|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^install-scrcpy|_install-scrcpy|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^install-openrgb|_install-openrgb|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^changelogs-testing|_changelogs-testing|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^configure-grub|_configure-grub|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i 's|^configure-snapshots|_configure-snapshots|' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i '/^alias.*distrobox-assemble/d' \
                            /usr/share/ublue-os/just/*.just || true
    sed -i '/^alias.*distrobox-new/d' \
                            /usr/share/ublue-os/just/*.just || true


    # Import justfiles to ujust
    log "INFO" "Importing justfiles to ujust"
    [[ ! -f "${import_file}" ]] &&
        curl -Lo "${import_file}" "${ublue_repo}/ublue-os-just/src/header.just"

    if [[ -f "${import_file}" ]]; then
        local justfile import_line
        for justfile in ${justfile_dir}/*.just; do
            # Copy justfiles to ujust default directory
            cp -dvf "${justfile}" /usr/share/ublue-os/just/
            # Add import line if it does not exists already
            import_line="import \"/usr/share/ublue-os/just/$(basename ${justfile})\""
            grep -w "${import_line}" "${import_file}" || {
                sed -i "/# Imports/a\\${import_line}" "${import_file}"
                log "INFO" "Added: '${import_line}' to ${import_file}"
            }
        done
    fi
    log "INFO" "Justfile(s) imported"

    log "INFO" "Full output of: ${import_file}"
    cat "${import_file}"
}

waydroid_setup() {
#    /usr/libexec/waydroid-container-restart
#    /usr/libexec/waydroid-container-start
#    /usr/libexec/waydroid-container-stop
#    /usr/libexec/waydroid-fix-controllers
#    /usr/share/applications/waydroid-container-restart.desktop
#    /etc/default/waydroid-launcher
    curl -Lo /usr/bin/waydroid-choose-gpu \
        "https://raw.githubusercontent.com/bazzite-org/waydroid-scripts/main/waydroid-choose-gpu.sh"
    chmod -v +x /usr/bin/waydroid-choose-gpu

    [[ ! -f "/usr/lib/waydroid/data/scripts/waydroid-net.sh~" ]] &&
            sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' \
                    /usr/lib/waydroid/data/scripts/waydroid-net.sh

    systemctl disable waydroid-container.service
}

extras() {
    curl -Lo /usr/share/applications/micro.desktop \
        https://raw.githubusercontent.com/zyedidia/micro/refs/heads/master/assets/packaging/micro.desktop
}

process_command() {
    case "${1}" in
        eza)
            eza
            ;;
        starship)
            starship
            ;;
        grex)
            grex
            ;;
        yazi)
            yazi
            ;;
        hblock)
            hblock
            ;;
        bandwhich)
            bandwhich
            ;;
        buttersnap)
            buttersnap
            ;;
        btdu)
            btdu
            ;;
        gocryptfs)
            gocryptfs
            ;;
        scrcpy)
            scrcpy
            ;;
        llama_cpp)
            llama_cpp_vk
            llama_cpp
            ;;
        pipes_sh)
            pipes_sh
            ;;
        ascii_image_converter)
            ascii_image_converter
            ;;
        ls_iommu)
            ls_iommu
            ;;
        ujust_setup)
            ujust_setup
            ;;
        waydroid_setup)
            waydroid_setup
            ;;
        extras)
            extras
            ;;
        *)
            die "Error: Unknown argument ${1}"
            ;;
    esac
}

# Process all provided arguments
for arg in "$@"; do
    log "INFO" "Installing and setting up: ${arg}"
    process_command "${arg}" || exit 1
done
rm -rf "${TMP_DIR}"
