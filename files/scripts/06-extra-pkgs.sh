#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

TMP_DIR="/tmp/extra_pkgs"
BIN_DIR="/usr/bin"
LIBEXEC_DIR="/usr/libexec"

ujust_setup() {
    local import_dir="/usr/share/ublue-os/just"
    local import_file="${import_dir}file"
    local justfile_dir="${BUILD_ROOT}/files/justfiles"

    mkdir -vp /usr/share/ublue-os/{just,lib-ujust}
    rpm -q just || {
        log "INFO" "Installing just"
        get_ghpkg --name "just" --repo "casey/just" \
                  --regx 'x86_64-unknown-linux-musl\.tar\.gz$' --negx '~~'
        log "INFO" "Done."
    }

    [[ ! -x "${BIN_DIR}/ujust" ]] && {
        log "INFO" "Installing ujust and ugum"
        get_ghraw --dstd "${BIN_DIR}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-just/src" --flist "ujust" "ugum"
        chmod -v +x "${BIN_DIR}"/{ujust,ugum}
        log "INFO" "Done."
    }

    # Needed files for luks tpm2 autounlock recipe
    [[ ! -f "${LIBEXEC_DIR}/luks-enable-tpm2-autounlock" ]] && {
        get_ghraw --dstd "/usr/lib/dracut/dracut.conf.d" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-luks/src" -f "90-ublue-luks.conf"
        get_ghraw --dstd "${LIBEXEC_DIR}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-luks/src" \
                  --flist "luks-enable-tpm2-autounlock" "luks-disable-tpm2-autounlock"
        chmod -v +x "${BIN_DIR}"/luks-{enable,disable}-tpm2-autounlock
    }

    # Fetch just recipes
    local fetched_justfiles="/tmp/fetched_justfiles"
    rpm -q waydroid && [[ ! -f "${import_dir}/82-bazzite-waydroid.just" ]] && {
        get_ghraw --dstd "${fetched_justfiles}" --repo "ublue-os/bazzite" \
                  --repod "system_files/desktop/shared/usr/share/ublue-os/just" \
                  -f "82-bazzite-waydroid.just"
        sed -i '/waydroid-container-restart.desktop/d' "${fetched_justfiles}/82-bazzite-waydroid.just"
        sed -i 's|source /usr/lib/ujust/ujust.sh|source /usr/lib/catcat-os/funcvar.sh|' \
                        "${fetched_justfiles}/82-bazzite-waydroid.just"
    }


    # Organize ujust
    log "INFO" "Categorizing justfiles"
#    sed '/^\[group/d' ${import_dir}/*.just
    sed -i -E '/^configure-broadcom-wl/i [group\("hardware"\)]' \
                            "${import_dir}"/50-akmods.just || true
    sed -i -E '/^enroll-secure-boot-key/i [group\("utilities"\)]' \
                            "${import_dir}"/00-default.just || true
    sed -i -E '/^(toggle-nvk|configure-(nvidia|nvidia-optimus))/i [group\("nvidia"\)]' \
                            "${import_dir}"/40-nvidia.just || true
    sed -i -E '/^install-resolve/i [group\("apps"\)]' \
                            "${import_dir}"/30-distrobox.just || true
    sed -i 's|^toggle-user-motd|_toggle-user-motd|' \
                            "${import_dir}"/00-default.just || true
    sed -i -e 's|^changelogs-testing|_changelogs-testing|' \
           -e 's|^distrobox-assemble|_distrobox-assemble|' \
           -e 's|^distrobox-new|_distrobox-new|' \
           -e 's|^setup-distrobox-app|_setup-distrobox-app|' \
           -e 's|^install-coolercontrol|_install-coolercontrol|' \
           -e 's|^install-scrcpy|_install-scrcpy|' \
           -e 's|^install-openrgb|_install-openrgb|' \
           -e 's|^changelogs-testing|_changelogs-testing|' \
           -e 's|^configure-grub|_configure-grub|' \
           -e 's|^configure-snapshots|_configure-snapshots|' \
           -e '/^alias.*distrobox-assemble/d' \
           -e '/^alias.*distrobox-new/d' \
                            "${import_dir}"/*.just || true


    # Import justfiles to ujust
    log "INFO" "Importing justfiles to ujust"
    [[ ! -f "${import_file}" ]] &&
        get_ghraw --dstf "${import_file}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-just/src" -f "header.just"

    if [[ -f "${import_file}" ]]; then
        mkdir -vp "${import_dir}"
        local justfile import_line
        for justfile in $(ls -A1 "${fetched_justfiles}"/*.just | tac) \
                        $(ls -A1 "${justfile_dir}"/*.just | tac); do
            # Copy justfiles to ujust default directory
            cp -dvf "${justfile}" "${import_dir}"/
            # Add import line if it does not exists already
            import_line="import \"${import_dir}/$(basename ${justfile})\""
            grep -w "${import_line}" "${import_file}" || {
                sed -i "/# Imports/a\\${import_line}" "${import_file}"
                log "INFO" "Added: '${import_line}' to ${import_file}"
            }
        done
    fi
    rm -rvf "${fetched_justfiles}"
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
    get_ghraw --dstd "${BIN_DIR}" --repo "ublue-os/waydroid-scripts" \
              -f "waydroid-choose-gpu.sh"
    chmod -v +x "${BIN_DIR}/waydroid-choose-gpu.sh"

    [[ ! -f "/usr/lib/waydroid/data/scripts/waydroid-net.sh~" ]] &&
            sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' \
                    /usr/lib/waydroid/data/scripts/waydroid-net.sh

    systemctl disable waydroid-container.service
}

wldrivers() {
    local ker="$(rpm -q --queryformat='%{evr}.%{arch}' kernel)"

    dnf5 -y install make gcc kernel-headers "kernel-devel-${ker}"
    dnf5 -y install haveged hostapd gcc-c++ gtk3-devel pkg-config qrencode-devel libpng-devel

    # Rtw89 drivers
    mkdir -vp /tmp/wldrivers
    git clone --depth 1 https://github.com/morrownr/rtw89 /tmp/wldrivers/rtw89
    sed -i "s|\`uname -r\`|${ker}|" \
                /tmp/wldrivers/rtw89/Makefile

    cd /tmp/wldrivers/rtw89
    make clean modules && make install &&
    make install_fw &&
    cp -vf rtw89.conf /etc/modprobe.d/
    cd -

    # Wihotspot
    git clone --depth 1 https://github.com/lakinduakash/linux-wifi-hotspot /tmp/wldrivers/wihotspot
    cd /tmp/wldrivers/wihotspot
    make &&
    make install
    cd -

    # Clean up
    # kernel-headers "kernel-devel-${ker}"
    dnf5 -y remove make gcc gcc-c++ \
                   gtk3-devel pkg-config qrencode-devel libpng-devel
    rm -rf /tmp/wldrivers
}

extras() {
    local desktopfiles_dir="/usr/share/applications"
    # micro.desktop
    get_ghraw --dstd "${desktopfiles_dir}" --repo "micro-editor/micro" \
              --repod "assets/packaging" -f "micro.desktop"

    # yazi.desktop
    get_ghraw --dstd "${desktopfiles_dir}" --repo "sxyazi/yazi" \
              --repod "assets" -f "yazi.desktop"
    get_ghraw --dstf "/usr/share/icons/yazi.png" --repo "sxyazi/yazi" \
              --repod "assets" -f "logo.png"

    # htop.desktop
    get_ghraw --dstd "${desktopfiles_dir}" --repo "htop-dev/htop" \
              -f "htop.desktop"
    sed -i 's|^Exec=.*|Exec=btm --basic|' "${desktopfiles_dir}/htop.desktop"

    # btop.desktop
    get_ghraw --dstd "${desktopfiles_dir}" --repo "aristocratos/btop" \
              -f "btop.desktop"
    sed -i 's|^Exec=.*|Exec=btm --config_location /etc/bottom/bottom.toml|' \
           "${desktopfiles_dir}/btop.desktop"
}

process_package() {
    case "${1}" in
        eza)
            get_ghpkg --name "${1}" --repo "eza-community/eza" \
                      --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        starship)
            get_ghpkg --name "${1}" --repo "starship/starship" \
                      --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        grex)
            get_ghpkg --name "${1}" --repo "pemistahl/grex" \
                      --regx 'x86_64-unknown-linux-musl\.tar\.gz$' --negx '~~'
            ;;
        yazi)
            get_ghpkg --name "${1}" --repo "sxyazi/yazi" \
                      --regx 'x86_64-unknown-linux-gnu\.zip$'
            place_executable "${auto_fold_dir[0]}" "ya"
            cp -vf "${auto_fold_dir[0]}/completions"/{ya,yazi}.bash \
                    /usr/share/bash-completion/completions/
            cp -vf "${auto_fold_dir[0]}/completions"/{ya,yazi}.fish \
                    /usr/share/fish/completions/
            ;;
        dnscrypt-proxy)
            get_ghpkg --name "${1}" --repo "DNSCrypt/dnscrypt-proxy" \
                      --regx 'linux_x86_64-.*\.tar\.gz$'
            get_ghraw --dstd "/etc/dnscrypt-proxy" --repo "DNSCrypt/dnscrypt-resolvers" \
                      --repod "v3" --flist "public-resolvers.md" "public-resolvers.md.minisig"
            ;;
        hblock)
            get_ghraw --dstf "${BIN_DIR}/${1}" --repo "hectorm/hblock" -f "${1}"
            chmod -v +x "${BIN_DIR}/${1}"
            get_ghraw --dstd "/etc/hblock" --repo "shriman-dev/dns-blocklist" \
                      --repod "hblock" --flist "sources.list" "deny.list" "allow.list"
            ;;
        bandwhich)
            get_ghpkg --name "${1}" --repo "imsnif/bandwhich" \
                      --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        buttersnap)
            get_ghraw --dstd "${BIN_DIR}" --repo "shriman-dev/buttersnap.sh" \
                      --flist "buttersnap.sh" "buttercopy.sh"
            chmod -v +x "${BIN_DIR}"/{buttersnap.sh,buttercopy.sh}
            ;;
        btdu)
            curl_get "${BIN_DIR}/${1}" \
                "https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64"
            chmod -v +x "${BIN_DIR}/${1}"
            ;;
        gocryptfs)
            get_ghpkg --name "${1}" --repo "rfjakob/gocryptfs" \
                      --regx 'linux-static_amd64\.tar\.gz$'
            ;;
        scrcpy)
            get_ghpkg --name "${1}" --repo "Genymobile/scrcpy" \
                      --regx 'linux-x86_64.*\.tar\.gz$' --libexec
            chmod -v +x "${LIBEXEC_DIR}/${1}/${1}"
            ln -svf "${LIBEXEC_DIR}/${1}/${1}" "${BIN_DIR}/${1}"
            ln -svf "${BIN_DIR}/adb" "${LIBEXEC_DIR}/${1}/adb"
            ;;
        llama-cpp)
            get_ghpkg --name "${1}" --repo "ggml-org/llama.cpp" \
                      --regx 'ubuntu-x64\.tar\.gz$' --negx 'vulkan' --libexec
            get_ghpkg --name "${1}-vk" --repo "ggml-org/llama.cpp" \
                      --regx 'ubuntu-vulkan-x64\.tar\.gz$' --libexec
            ;;
        pipes-sh)
            chmod -v +x "${BIN_DIR}/pipes.sh"
            ;;
        ascii-image-converter)
            chmod -v +x "${BIN_DIR}/${1}"
            ;;
        ls-iommu)
            get_ghpkg --name "${1}" --repo "HikariKnight/ls-iommu" \
                      --regx 'Linux_x86_64\.tar\.gz$'
            ;;
        ujust_setup)
            ujust_setup
            ;;
        waydroid_setup)
            waydroid_setup
            ;;
        wldrivers)
            wldrivers
            ;;
        extras)
            extras
            ;;
        *)
            die "Error: Unknown package ${1}"
            ;;
    esac
}

# Process all provided arguments
for pkg in "$@"; do
    log "INFO" "Installing and setting up: ${pkg}"
    process_package "${pkg}"
    log "INFO" "Operation done for: ${pkg}"
done
rm -rf "${TMP_DIR}"
