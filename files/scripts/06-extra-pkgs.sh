#!/usr/bin/env bash
source ${BUILD_SCRIPT_LIB}
set -ouex pipefail

TMP_DIR="/tmp/extra_pkgs"
USRBIN="/usr/bin"
USRLIBEXEC="/usr/libexec"

ujust_setup() {
    local import_dir="/usr/share/ublue-os/just"
    local import_file="${import_dir}file"
    local justfile_dir="$(dirname ${BUILD_SETUP_DIR})/justfiles"

    mkdir -vp /usr/share/ublue-os/{just,lib-ujust}
    rpm -q just || {
        log "INFO" "Installing just"
        get_ghpkg --name "just" --repo "casey/just" \
                  --regx 'x86_64-unknown-linux-musl\.tar\.gz$' --negx '~~'
        log "INFO" "Done."
    }

    [[ ! -x "${USRBIN}/ujust" ]] && {
        log "INFO" "Installing ujust and ugum"
        get_ghraw --dstd "${USRBIN}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-just/src" --flist "ujust" "ugum"
        chmod -v +x "${USRBIN}"/{ujust,ugum}
        log "INFO" "Done."
    }

    # Needed files for luks tpm2 autounlock recipe
    [[ ! -f "${USRLIBEXEC}/luks-enable-tpm2-autounlock" ]] && {
        get_ghraw --dstd "/usr/lib/dracut/dracut.conf.d" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-luks/src" -f "90-ublue-luks.conf"
        get_ghraw --dstd "${USRLIBEXEC}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-luks/src" \
                  --flist "luks-enable-tpm2-autounlock" "luks-disable-tpm2-autounlock"
        chmod -v +x "${USRBIN}"/luks-{enable,disable}-tpm2-autounlock
    }

    # Fetch just recipes
    local fetched_justfiles="/tmp/fetched_justfiles"
    rpm -q waydroid && [[ ! -f "${import_dir}/82-bazzite-waydroid.just" ]] && {
        get_ghraw --dstd "${fetched_justfiles}" --repo "ublue-os/bazzite" \
                  --repod "system_files/desktop/shared/usr/share/ublue-os/just" \
                  -f "82-bazzite-waydroid.just"
        sed -i '/waydroid-container-restart.desktop/d' "${fetched_justfiles}/82-bazzite-waydroid.just"
        sed -i 's|source /usr/lib/ujust/ujust.sh|source /usr/lib/catcat/funcvar.sh|' \
                        "${fetched_justfiles}/82-bazzite-waydroid.just"
    }


    # Organize ujust
    log "INFO" "Categorizing justfiles"
#    sed '/^\[group/d' ${import_dir}/*.just
    sed -i -E '/^configure-broadcom-wl/i [group\("hardware"\)]' \
                            ${import_dir}/50-akmods.just || true
    sed -i -E '/^enroll-secure-boot-key/i [group\("utilities"\)]' \
                            ${import_dir}/00-default.just || true
    sed -i -E '/^(toggle-nvk|configure-(nvidia|nvidia-optimus))/i [group\("nvidia"\)]' \
                            ${import_dir}/40-nvidia.just || true
    sed -i -E '/^install-resolve/i [group\("apps"\)]' \
                            ${import_dir}/30-distrobox.just || true
    sed -i 's|^toggle-user-motd|_toggle-user-motd|' \
                            ${import_dir}/00-default.just || true
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
                            ${import_dir}/*.just || true


    # Import justfiles to ujust
    log "INFO" "Importing justfiles to ujust"
    [[ ! -f "${import_file}" ]] &&
        get_ghraw --dstf "${import_file}" --repo "ublue-os/packages" \
                  --repod "packages/ublue-os-just/src" -f "header.just"

    if [[ -f "${import_file}" ]]; then
        mkdir -vp ${import_dir}
        local justfile import_line
        for justfile in $(ls -A1 ${fetched_justfiles}/*.just | tac) \
                        $(ls -A1 ${justfile_dir}/*.just | tac); do
            # Copy justfiles to ujust default directory
            cp -dvf "${justfile}" ${import_dir}/
            # Add import line if it does not exists already
            import_line="import \"${import_dir}/$(basename ${justfile})\""
            grep -w "${import_line}" "${import_file}" || {
                sed -i "/# Imports/a\\${import_line}" "${import_file}"
                log "INFO" "Added: '${import_line}' to ${import_file}"
            }
        done
    fi
    rm -rvf ${fetched_justfiles}
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
    get_ghraw --dstd "${USRBIN}" --repo "ublue-os/waydroid-scripts" \
              -f "waydroid-choose-gpu.sh"
    chmod -v +x "${USRBIN}/waydroid-choose-gpu.sh"

    [[ ! -f "/usr/lib/waydroid/data/scripts/waydroid-net.sh~" ]] &&
            sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' \
                    /usr/lib/waydroid/data/scripts/waydroid-net.sh

    systemctl disable waydroid-container.service
}

wldrivers() {
    # Make space for rtw89 drivers in kernel extra
    mkdir -vp "/usr/lib/firmware"
    mkdir -vp "/usr/lib/modules/$(rpm -q --queryformat='%{evr}.%{arch}' kernel)/extra"
    ln -svf "/usr/local/lib/firmware/rtw89" "/usr/lib/firmware/rtw89"
    ln -svf "/usr/local/lib/modules/catcat-kernel/extra/rtw89" \
            "/usr/lib/modules/$(rpm -q --queryformat='%{evr}.%{arch}' kernel)/extra/rtw89"
}

extras() {
    # micro.desktop
    get_ghraw --dstd "/usr/share/applications" --repo "zyedidia/micro" \
              --repod "assets/packaging" -f "micro.desktop"

    # yazi.desktop
    get_ghraw --dstd "/usr/share/applications" --repo "sxyazi/yazi" \
              --repod "assets" -f "yazi.desktop"
    get_ghraw --dstf "/usr/share/icons/yazi.png" --repo "sxyazi/yazi" \
              --repod "assets" -f "logo.png"
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
            get_ghraw --dstf "${USRBIN}/${1}" --repo "hectorm/hblock" -f "${1}"
            chmod -v +x "${USRBIN}/${1}"
            get_ghraw --dstd "/etc/hblock" --repo "shriman-dev/dns-blocklist" \
                      --repod "hblock" --flist "sources.list" "deny.list" "allow.list"
            ;;
        bandwhich)
            get_ghpkg --name "${1}" --repo "imsnif/bandwhich" \
                      --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        buttersnap)
            get_ghraw --dstd "${USRBIN}" --repo "shriman-dev/buttersnap.sh" \
                      --flist "buttersnap.sh" "buttercopy.sh"
            chmod -v +x "${USRBIN}"/{buttersnap.sh,buttercopy.sh}
            ;;
        btdu)
            curl_get "${USRBIN}/btdu" \
                "https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64"
            chmod -v +x "${USRBIN}/btdu"
            ;;
        gocryptfs)
            get_ghpkg --name "${1}" --repo "rfjakob/gocryptfs" \
                      --regx 'linux-static_amd64\.tar\.gz$'
            ;;
        scrcpy)
            get_ghpkg --name "${1}" --repo "Genymobile/scrcpy" \
                      --regx 'linux-x86_64.*\.tar\.gz$' --libexec
            chmod -v +x "${USRLIBEXEC}/${1}/${1}"
            ln -svf "${USRLIBEXEC}/${1}/${1}" "${USRBIN}/${1}"
            ln -svf "${USRBIN}/adb" "${USRLIBEXEC}/${1}/adb"
            ;;
        llama-cpp)
            get_ghpkg --name "${1}" --repo "ggml-org/llama.cpp" \
                      --regx 'ubuntu-x64\.tar\.gz$' --negx 'vulkan' --libexec
            get_ghpkg --name "${1}-vk" --repo "ggml-org/llama.cpp" \
                      --regx 'ubuntu-vulkan-x64\.tar\.gz$' --libexec
            ;;
        pipes-sh)
            chmod -v +x "${USRBIN}/pipes.sh"
            ;;
        ascii-image-converter)
            chmod -v +x "${USRBIN}/${1}"
            ;;
        ls-iommu)
            get_ghpkg --name "${1}" --repo "rfjakob/gocryptfs" \
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
