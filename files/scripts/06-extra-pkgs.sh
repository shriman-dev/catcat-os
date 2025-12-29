#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh
set -x
TMP_DIR="/tmp/catcat_extra_pkgs"

starship() {
    local starship_repo="https://api.github.com/repos/starship/starship"
    local starship_tar="${TMP_DIR}/starship.tar.gz"
    log "INFO" "Installing starship"
    mkdir -vp "${starship_tar}.extract"

    curl -Lo "${starship_tar}" $(curl -s -X GET "${starship_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)

    tar -xvf "${starship_tar}" -C "${starship_tar}.extract"
    cp -dvf "${starship_tar}.extract/starship" "/usr/bin"/
    chmod -v +x /usr/bin/starship
    rm -rf "${starship_tar}" "${starship_tar}.extract"

    log "INFO" "Done."
}

eza() {
    local eza_repo="https://github.com/eza-community/eza"
    local eza_tar="${TMP_DIR}/eza.tar.gz"
    log "INFO" "Installing eza"
    mkdir -vp "${eza_tar}.extract"

    curl -Lo "${eza_tar}" "${eza_repo}/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"

    tar -xvf "${eza_tar}" -C "${eza_tar}.extract"
    cp -dvf "${eza_tar}.extract/eza" /usr/bin/
    chmod -v +x /usr/bin/eza
    rm -rf "${eza_tar}" "${eza_tar}.extract"

    log "INFO" "Done."
}

grex() {
    local grex_repo="https://api.github.com/repos/pemistahl/grex"
    local grex_tar="${TMP_DIR}/grex.tar.gz"
    log "INFO" "Installing grex"
    mkdir -vp "${grex_tar}.extract"

    curl -Lo "${grex_tar}" $(curl -s -X GET "${grex_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-musl.tar.gz"' | cut -d '"' -f4)

    tar -xvf "${grex_tar}" -C "${grex_tar}.extract"
    cp -dvf "${grex_tar}.extract/grex" "/usr/bin"/
    chmod -v +x /usr/bin/grex
    rm -rf "${grex_tar}" "${grex_tar}.extract"

    log "INFO" "Done."
}

yazi() {
    local yazi_repo="https://github.com/sxyazi/yazi"
    local yazi_repo_raw="https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main"
    local yazi_zip="${TMP_DIR}/yazi.zip"
    log "INFO" "Installing yazi"
    mkdir -vp "${yazi_zip}.extract"

    curl -Lo "${yazi_zip}" "${yazi_repo}/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    curl -Lo /usr/share/applications/yazi.desktop "${yazi_repo_raw}/assets/yazi.desktop"
    curl -Lo /usr/share/icons/yazi.png "${yazi_repo_raw}/assets/logo.png"

    cd "${yazi_zip}.extract"
    unzip "${yazi_zip}"
    cd -
    cp -dvf "${yazi_zip}.extract/yazi-x86_64-unknown-linux-gnu"/{ya,yazi} /usr/bin/
    chmod -v +x /usr/bin/{ya,yazi}
    cp -dvf "${yazi_zip}.extract/yazi-x86_64-unknown-linux-gnu/completions/ya.bash" \
                    /usr/share/bash-completion/completions/
    cp -dvf "${yazi_zip}.extract/yazi-x86_64-unknown-linux-gnu/completions/yazi.fish" \
                    /usr/share/fish/completions/
    rm -rf "${yazi_zip}" "${yazi_zip}.extract"

    log "INFO" "Done."
}

hblock() {
    local hblock_confd="/etc/hblock"
    local hblock_repo="https://raw.githubusercontent.com/hectorm/hblock/refs/heads/master"
    local dns_blocklist_repo="https://raw.githubusercontent.com/shriman-dev/dns-blocklist/refs/heads/main"
    log "INFO" "Installing hblock"

    curl -Lo "/usr/bin/hblock" "${hblock_repo}/hblock"
    chmod -v +x "/usr/bin/hblock"

    # Get hblock config
    log "DEBUG" "Getting hblock configuration"
    mkdir -vp "${hblock_confd}"
    curl -Lo "${hblock_confd}/sources.list" "${dns_blocklist_repo}/hblock/sources.list"
    curl -Lo "${hblock_confd}/deny.list" "${dns_blocklist_repo}/hblock/deny.list"
    curl -Lo "${hblock_confd}/allow.list" "${dns_blocklist_repo}/hblock/allow.list"

    log "INFO" "Done."
}

bandwhich() {
    local bandwhich_repo="https://api.github.com/repos/imsnif/bandwhich"
    local bandwhich_tar="${TMP_DIR}/bandwhich.tar.gz"
    log "INFO" "Installing bandwhich"
    mkdir -vp "${bandwhich_tar}.extract"

    curl -Lo "${bandwhich_tar}" $(curl -s -X GET "${bandwhich_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)

    tar -xvf "${bandwhich_tar}" -C "${bandwhich_tar}.extract"
    cp -dvf "${bandwhich_tar}.extract/bandwhich" "/usr/bin"/
    chmod -v +x /usr/bin/bandwhich
    rm -rf "${bandwhich_tar}" "${bandwhich_tar}.extract"

    log "INFO" "Done."
}

buttersnap() {
    local buttersnap_repo="https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main"
    log "INFO" "Installing btdu"

    curl -Lo "/usr/bin/buttersnap.sh" "${buttersnap_repo}/buttersnap.sh"
    chmod -v +x "/usr/bin/buttersnap.sh"

    curl -Lo "/usr/bin/buttercopy.sh" "${buttersnap_repo}/buttercopy.sh"
    chmod -v +x "/usr/bin/buttercopy.sh"

    log "INFO" "Done."
}

btdu() {
    local btdu_repo="https://github.com/CyberShadow/btdu"
    log "INFO" "Installing btdu"

    curl -Lo "/usr/bin/btdu" "${btdu_repo}/releases/latest/download/btdu-static-x86_64"

    chmod -v +x "/usr/bin/btdu"
    log "INFO" "Done."
}

gocryptfs() {
    local gocryptfs_repo="https://api.github.com/repos/rfjakob/gocryptfs"
    local gocryptfs_tar="${TMP_DIR}/gocryptfs.tar.gz"
    log "INFO" "Installing gocryptfs"
    mkdir -vp "${gocryptfs_tar}.extract"

    curl -Lo "${gocryptfs_tar}" $(curl -s -X GET "${gocryptfs_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux-static_amd64.tar.gz"' | cut -d '"' -f4)

    tar -xvf "${gocryptfs_tar}" -C "${gocryptfs_tar}.extract"
    cp -dvf "${gocryptfs_tar}.extract/gocryptfs" "/usr/bin"/
    chmod -v +x /usr/bin/gocryptfs
    rm -rf "${gocryptfs_tar}" "${gocryptfs_tar}.extract"

    log "INFO" "Done."
}

scrcpy() {
    local scrcpy_repo="https://api.github.com/repos/Genymobile/scrcpy"
    local scrcpy_tar="${TMP_DIR}/scrcpy.tar.gz"
    local usrlibexec_scrcpy="/usr/libexec/scrcpy"
    log "INFO" "Installing scrcpy"
    mkdir -vp "${scrcpy_tar}.extract" "${usrlibexec_scrcpy}"

    curl -Lo "${scrcpy_tar}" $(curl -s -X GET "${scrcpy_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux-x86_64-.*.tar.gz"' | cut -d '"' -f4)

    tar -xvf "${scrcpy_tar}" -C "${scrcpy_tar}.extract"
    cp -dvf "${scrcpy_tar}.extract"/*/* "${usrlibexec_scrcpy}"/
    ln -svf /usr/bin/adb "${usrlibexec_scrcpy}/adb"
    ln -svf "${usrlibexec_scrcpy}/scrcpy" /usr/bin/scrcpy
    chmod -v +x "${usrlibexec_scrcpy}/scrcpy"
    rm -rf "${scrcpy_tar}" "${scrcpy_tar}.extract"

    log "INFO" "Done."
}

llama_cpp() {
    local llama_cpp_repo="https://api.github.com/repos/ggml-org/llama.cpp"
    local llama_cpp_zip="${TMP_DIR}/llama-cpp-vulkan.zip"
    local usrlibexec_llama_cpp="/usr/libexec/llama_cpp_vulkan"
    log "INFO" "Installing llama_cpp"
    mkdir -vp "${llama_cpp_zip}.extract" "${usrlibexec_llama_cpp}"

    curl -Lo "${llama_cpp_zip}" $(curl -s -X GET "${llama_cpp_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*ubuntu-vulkan-x64.zip"' | cut -d '"' -f4)

    cd "${llama_cpp_zip}.extract"
    unzip "${llama_cpp_zip}"
    cd -
    mv -v "${llama_cpp_zip}.extract/build/bin" "${usrlibexec_llama_cpp}"/
    chmod -v +x "${usrlibexec_llama_cpp}/bin"/llama-{batched-bench,bench,cli,imatrix,gguf-split,mtmd-cli,quantize,run,server,tokenize,tts}
    ln -svf "${usrlibexec_llama_cpp}/bin"/llama-{batched-bench,bench,cli,imatrix,gguf-split,mtmd-cli,quantize,run,server,tokenize,tts} /usr/bin/
    rm -rf "${llama_cpp_zip}" "${llama_cpp_zip}.extract"

    log "INFO" "Done."
}

pipes_sh() {
    local pipes_sh_repo="https://raw.githubusercontent.com/pipeseroni/pipes.sh/refs/heads/master"
    log "INFO" "Installing pipes.sh"

#    curl -Lo "/usr/bin/pipes.sh" "${pipes_sh_repo}/pipes.sh"
    chmod -v +x "/usr/bin/pipes.sh"

    log "INFO" "Done."
}

ascii_image_converter() {
    local ascii_ic_repo="https://github.com/TheZoraiz/ascii-image-converter"
    local ascii_ic_tar="${TMP_DIR}/ascii_ic.tar.gz"
    log "INFO" "Installing ascii-image-converter"
#    mkdir -vp "${ascii_ic_tar}.extract"

#    curl -Lo "${ascii_ic_tar}" "${ascii_ic_repo}/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz"

#    tar -xvf "${ascii_ic_tar}" -C "${ascii_ic_tar}.extract"
#    cp -dvf "${ascii_ic_tar}.extract"/*/ascii-image-converter "/usr/bin"/
    chmod -v +x /usr/bin/ascii-image-converter
#    rm -rf "${ascii_ic_tar}" "${ascii_ic_tar}.extract"

    log "INFO" "Done."
}

ls_iommu() {
    local ls_iommu_repo="https://api.github.com/repos/HikariKnight/ls-iommu"
    local ls_iommu_tar="${TMP_DIR}/ls_iommu.tar.gz"
    log "INFO" "Installing ls-iommu"
    mkdir -vp "${ls_iommu_tar}.extract"

    curl -Lo "${ls_iommu_tar}" $(curl -s -X GET "${ls_iommu_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*Linux_x86_64.tar.gz"' | cut -d '"' -f4)


    tar -xvf "${ls_iommu_tar}" -C "${ls_iommu_tar}.extract"
    cp -dvf "${ls_iommu_tar}.extract/ls-iommu" "/usr/bin"/
    chmod -v +x /usr/bin/ls-iommu
    rm -rf "${ls_iommu_tar}" "${ls_iommu_tar}.extract"

    log "INFO" "Done."
}

ujust_setup() {
    local just_repo="https://api.github.com/repos/casey/just"
    local just_tar="${TMP_DIR}/just.tar.gz"
    local ublue_repo="https://raw.githubusercontent.com/ublue-os/packages/refs/heads/main/packages"
    local bazzite_repo="https://raw.githubusercontent.com/ublue-os/bazzite/refs/heads/main/system_files/desktop/shared/usr/share/ublue-os/just"
    local import_file="/usr/share/ublue-os/justfile"
    local justfile_dir="$(dirname ${SETUP_DIR})/justfiles"

    mkdir -vp /usr/share/ublue-os/{just,lib-ujust}
    [[ ! -f "/usr/bin/just" ]] && {
        log "INFO" "Installing just"
        mkdir -vp "${just_tar}.extract"

        curl -Lo "${just_tar}" $(curl -s -X GET "${just_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-musl.tar.gz"' | cut -d '"' -f4)

        tar -xvf "${just_tar}" -C "${just_tar}.extract"
        cp -dvf "${just_tar}.extract/just.1" "/usr/share/man/man1/just.1"
        cp -dvf "${just_tar}.extract/just" "/usr/bin"/
        chmod -v +x /usr/bin/just
        rm -rf "${just_tar}" "${just_tar}.extract"
        log "INFO" "Done."
    }

    [[ ! -f "/usr/bin/ujust" ]] && {
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
                log "DEBUG" "Added: '${import_line}' to ${import_file}"
            }
        done
    fi
    log "INFO" "All Justfile imports are done."

    log "INFO" "Full output of: ${import_file}"
    cat "${import_file}"
}

waydroid_setup() {
    log "INFO" "Waydroid setup"
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
    log "INFO" "Done."
}

extras() {
    log "INFO" "Getting extra confs"

    curl -Lo /usr/share/applications/micro.desktop \
        https://raw.githubusercontent.com/zyedidia/micro/refs/heads/master/assets/packaging/micro.desktop
    log "INFO" "Done."
}

process_command() {
    mkdir -vp "${TMP_DIR}"
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
    rm -rf "${TMP_DIR}"
}

# Process all provided arguments
for arg in "$@"; do
    process_command "${arg}" || exit 1
done
