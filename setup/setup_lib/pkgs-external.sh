#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euox pipefail

TMP_DIR="/tmp/pkgs_external"
FETCHED="${BUILD_CACHE_DIR}/fetched"
SYS_CACHE="${BUILD_CACHE_DIR}/system-pkgs-external"
BIN_DIR="${SYS_CACHE}/usr/bin"
LIBEXEC_DIR="${SYS_CACHE}/usr/libexec"

# Function to cache get_ghpkg
_get_ghpkg() {
    local pkg_name pkg_repo pkg_regx pkg_negx="" islibexec=0
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --name)    pkg_name="${2}"; shift ;; # Set package name
            --repo)    pkg_repo="${2}"; shift ;; # GitHub repo (owner/repo)
            --regx)    pkg_regx="${2}"; shift ;; # Filter release assets by regex
            --negx)    pkg_negx="${2}"; shift ;; # Exclude assets matching by regex
            --libexec) islibexec=1 ;;  # Installs package contents into libexec
            *)         die "Unknown option: ${1}" ;;
        esac
        shift
    done
    if [[ ${islibexec} -ne 1 ]]; then
        if [[ -x "${BIN_DIR}/${pkg_name}" ]]; then
            log "NOTE" "Package skipped - Executable exists: ${BIN_DIR}/${pkg_name}"
        else
            get_ghpkg --name "${pkg_name}" --repo "${pkg_repo}" --regx "${pkg_regx}" \
                      --negx "${pkg_negx:-musl}"
        fi
    else
        if [[ -d "${LIBEXEC_DIR}/${pkg_name}" && "$(ls -A "${LIBEXEC_DIR}/${pkg_name}")" ]]; then
            log "NOTE" "Lib-package skipped - Non-empty directory exists: ${LIBEXEC_DIR}/${pkg_name}"
        else
            get_ghpkg --name "${pkg_name}" --repo "${pkg_repo}" --regx "${pkg_regx}" \
                      --negx "${pkg_negx:-musl}" --libexec
        fi
    fi
}

ucat_setup() {
    local import_dir="/usr/share/${PROJECT_NAME}/just"
    local import_file="${import_dir}file"
    local justfile_dir="${BUILD_ROOT_DIR}/files/justfiles"

    mkdir -vp "${import_dir}"

    log "INFO" "Installing ucat and ugum"
    check_file_inplace "/usr/bin/ucat"
    place_executable "${BUILD_CACHE_DIR}/conf_repos/ublue_packages" 'ugum'
    log "INFO" "Done."

    # Modify fetched just recipes
    local fetched_justfiles="${BUILD_CACHE_DIR}/fetched/justfiles"
    sed -i '/waydroid-container-restart.desktop/d' "${fetched_justfiles}/82-bazzite-waydroid.just"
    sed -i 's|source /usr/lib/ujust/ujust.sh|source /usr/lib/catcat-os/funcvar.sh|' \
           "${fetched_justfiles}/82-bazzite-waydroid.just"

    # Import justfiles to ucat
    log "INFO" "Importing justfiles to ucat"
    check_file_inplace "${import_file}"

    if [[ -f "${import_file}" ]]; then
        local justfile import_line
        for justfile in $(ls -A1 "${fetched_justfiles}"/*.just | tac) \
                        $(ls -A1 "${justfile_dir}"/*.just | tac); do
            # Copy justfiles to ucat default directory
            cp -vf "${justfile}" "${import_dir}"/
            # Add import line if it does not exists already
            import_line="import \"${import_dir}/$(basename ${justfile})\""
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
    get_ghraw --dstd "${BIN_DIR}" --repo "ublue-os/waydroid-scripts" \
               -f "waydroid-choose-gpu.sh"
    chmod -v +x "${BIN_DIR}/waydroid-choose-gpu.sh"

    if [[ ! -f "/usr/lib/waydroid/data/scripts/waydroid-net.sh~" ]]; then
        sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' \
                    "/usr/lib/waydroid/data/scripts/waydroid-net.sh"
    fi
    systemctl disable waydroid-container.service
}

acpi_call() {
    export KVER="$(rpm -q ${CUSTOM_KERNEL:-kernel} --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n')"

    ensure_repo "https://github.com/nix-community/acpi_call.git" \
                "${BUILD_CACHE_DIR}/conf_repos/acpi_call"

    cd "${BUILD_CACHE_DIR}/conf_repos/acpi_call"
    make
    install -v -D -m 0644 "${BUILD_CACHE_DIR}/conf_repos/acpi_call"/*.ko \
                  -t "/usr/lib/modules/${KVER}/extra/acpi_call"/

    depmod -a "${KVER}"
    echo "acpi_call" > "/etc/modules-load.d/acpi_call.conf"

    cd -
    unset KVER
}

#wldrivers() {
#    local ker="$(rpm -q --queryformat='%{evr}.%{arch}' kernel)"

#    dnf5 -y install make gcc gcc-c++ kernel-headers kernel-devel-matched \
#                    haveged hostapd gtk3-devel pkg-config qrencode-devel libpng-devel

#    # Rtw89 drivers
#    mkdir -vp /tmp/wldrivers
#    git clone --depth 1 https://github.com/morrownr/rtw89 /tmp/wldrivers/rtw89
#    sed -i "s|\`uname -r\`|${ker}|" \
#                /tmp/wldrivers/rtw89/Makefile

#    cd /tmp/wldrivers/rtw89
#    make clean modules && make install &&
#    make install_fw &&
#    cp -vf rtw89.conf /etc/modprobe.d/
#    cd -

#    # Wihotspot
#    git clone --depth 1 https://github.com/lakinduakash/linux-wifi-hotspot /tmp/wldrivers/wihotspot
#    cd /tmp/wldrivers/wihotspot
#    make &&
#    make install
#    cd -

#    # Clean up
#    # kernel-headers "kernel-devel-${ker}"
#    dnf5 -y remove gtk3-devel pkg-config qrencode-devel libpng-devel
#    rm -rf /tmp/wldrivers
#}

extras() {
    local dfiles_dir="${SYS_CACHE}/usr/share/applications"
    local icons_dir="${SYS_CACHE}/usr/share/icons"
    # micro.desktop
    get_ghraw --dstd "${dfiles_dir}" --repo "micro-editor/micro" \
              --repod "assets/packaging" -f "micro.desktop"

    # yazi.desktop
    get_ghraw --dstd "${dfiles_dir}" --repo "sxyazi/yazi" \
              --repod "assets" -f "yazi.desktop"
    get_ghraw --dstf "${icons_dir}/yazi.png" --repo "sxyazi/yazi" \
              --repod "assets" -f "logo.png"

    # htop.desktop
    get_ghraw --dstd "${dfiles_dir}" --repo "htop-dev/htop" \
              -f "htop.desktop"
    sed -i 's|^Exec=.*|Exec=btm --basic|' "${dfiles_dir}/htop.desktop"

    # btop.desktop
    get_ghraw --dstd "${dfiles_dir}" --repo "aristocratos/btop" \
              -f "btop.desktop"
    sed -i 's|^Exec=.*|Exec=btm --config_location /etc/bottom/bottom.toml|' \
           "${dfiles_dir}/btop.desktop"
}

process_package() {
    case "${1}" in
        eza)
            _get_ghpkg --name "${1}" --repo "eza-community/eza" \
                       --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        starship)
            _get_ghpkg --name "${1}" --repo "starship/starship" \
                       --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        grex)
            _get_ghpkg --name "${1}" --repo "pemistahl/grex" \
                       --regx 'x86_64-unknown-linux-musl\.tar\.gz$' --negx '~##~'
            ;;
        yazi)
            local bash_complt="${SYS_CACHE}/usr/share/bash-completion/completions"
            local fish_complt="${SYS_CACHE}/usr/share/fish/completions"
            mkdir -vp "${bash_complt}" "${fish_complt}"
            _get_ghpkg --name "${1}" --repo "sxyazi/yazi" \
                       --regx 'x86_64-unknown-linux-gnu\.zip$'
            if [[ -n "${auto_fold_dir:-}" ]]; then
                place_executable "${auto_fold_dir[0]}" "ya"
                cp -vf "${auto_fold_dir[0]}/completions"/{ya,yazi}.bash "${bash_complt}"/
                cp -vf "${auto_fold_dir[0]}/completions"/{ya,yazi}.fish "${fish_complt}"/
                unset auto_fold_dir
            fi
            ;;
        dnscrypt-proxy)
            local dnscrypt_confd="${SYS_CACHE}/etc/dnscrypt-proxy"
            _get_ghpkg --name "${1}" --repo "DNSCrypt/dnscrypt-proxy" \
                       --regx 'linux_x86_64-.*\.tar\.gz$'
            get_ghraw --dstd "${dnscrypt_confd}" --repo "DNSCrypt/dnscrypt-resolvers" \
                      --repod "v3" --flist "public-resolvers.md" "public-resolvers.md.minisig"
            ;;
        hblock)
            local hblock_confd="${SYS_CACHE}/etc/hblock"
            get_ghraw --dstf "${BIN_DIR}/${1}" --repo "hectorm/hblock" -f "${1}"
            chmod -v +x "${BIN_DIR}/${1}"
            get_ghraw --dstd "${hblock_confd}" --repo "shriman-dev/dns-blocklist" \
                      --repod "hblock" --flist "sources.list" "deny.list" "allow.list"
            ;;
        bandwhich)
            _get_ghpkg --name "${1}" --repo "imsnif/bandwhich" \
                       --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        buttersnap)
            get_ghraw --dstd "${BIN_DIR}" --repo "shriman-dev/buttersnap.sh" \
                      --flist "buttersnap.sh" "buttercopy.sh"
            chmod -v +x "${BIN_DIR}"/{buttersnap.sh,buttercopy.sh}
            ;;
        btdu)
            if [[ ! -x "${BIN_DIR}/${1}" ]]; then
                curl_get "${TMP_DIR}/btdu-static-x86_64" \
                "https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64"
                curl_get "${TMP_DIR}/btdu-static-x86_64.sha256sum" \
                "https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64.sha256sum"
                cd "${TMP_DIR}" && sha256sum -c btdu-static-x86_64.sha256sum && cd -
                cp -vf "${TMP_DIR}/btdu-static-x86_64" "${BIN_DIR}/${1}"
            fi
            chmod -v +x "${BIN_DIR}/${1}"
            ;;
        gocryptfs)
            _get_ghpkg --name "${1}" --repo "rfjakob/gocryptfs" \
                       --regx 'linux-static_amd64\.tar\.gz$'
            ;;
        scrcpy)
            _get_ghpkg --name "${1}" --repo "Genymobile/scrcpy" \
                       --regx 'linux-x86_64.*\.tar\.gz$' --libexec
            chmod -v +x "${LIBEXEC_DIR}/${1}/${1}"
            ln -srvf "${LIBEXEC_DIR}/${1}/${1}" "${BIN_DIR}/${1}"
            ln -srvf "${BIN_DIR}/adb" "${LIBEXEC_DIR}/${1}/adb"
            ;;
        uv)
            _get_ghpkg --name "${1}" --repo "astral-sh/uv" \
                       --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            if [[ -n "${auto_fold_dir:-}" ]]; then
                place_executable "${auto_fold_dir[0]}" "uvx"
                unset auto_fold_dir
            fi
            ;;
        llama-cpp)
            _get_ghpkg --name "${1}-vk" --repo "ggml-org/llama.cpp" \
                       --regx 'ubuntu-vulkan-x64\.tar\.gz$' --libexec
            ;;
        chess-tui)
            _get_ghpkg --name "${1}" --repo "thomas-mauran/chess-tui" \
                       --regx 'x86_64-unknown-linux-gnu\.tar\.gz$'
            ;;
        pipes-sh)
            chmod -v +x "/usr/bin/pipes.sh"
            ;;
        ascii-image-converter)
            chmod -v +x "/usr/bin/${1}"
            ;;
        ls-iommu)
            _get_ghpkg --name "${1}" --repo "HikariKnight/ls-iommu" \
                       --regx 'Linux_x86_64\.tar\.gz$'
            ;;
        acpi_call)
            acpi_call
            ;;
        ucat_setup)
            ucat_setup
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

log "INFO" "Copying cached files"
ocopy "${SYS_CACHE}" /
