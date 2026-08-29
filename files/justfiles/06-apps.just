# Install default and extra flatpak apps
[group("apps")]
install-catcat-flatpaks:
    #!/usr/bin/bash
    sudo /usr/libexec/catcat-flatpak-manager --install-all

# App for controlling fans on msi laptops
[group("apps")]
install-mcontrolcenter:
    #!/usr/bin/env -S sudo -- /bin/bash
    source /usr/lib/catcat-os/funcvar.sh
    log "INFO" "Installing mcontrolcenter"
    TMP_DIR="/tmp/extra_pkgs"
    pkg_name="mcontrolcenter"
    latest_pkg_url="$(latest_ghpkg_url 'dmitry-s93/MControlCenter' 'bin\.tar\.gz$')"
    pkg_archive="${TMP_DIR}/$(basename ${latest_pkg_url})"

    umask 0022
    mkdir -vp "${pkg_archive}.extract"
    curl_get "${pkg_archive}" "${latest_pkg_url}"
    unarchive "${pkg_archive}" "${pkg_archive}.extract"

    auto_fold_dir=($(populated_or_afile_dirs "${pkg_archive}.extract"))

    sed -i "s|/usr/|/usr/local/|" "${auto_fold_dir[0]}"/install.sh
    sed -i "s|/usr/|/usr/local/|" "${auto_fold_dir[0]}"/app/mcontrolcenter.helper.service
    cd "${auto_fold_dir[0]}"
    "${auto_fold_dir[0]}"/install.sh
    ln -svf /usr/local/share/applications/mcontrolcenter.desktop \
                ${SUDO_USER}/.config/autostart/mcontrolcenter.desktop
    cd -
    rm -rf "${TMP_DIR}"
    log "INFO" "All Done."

# Install llama.cpp vulkan. Running this again will update llama.cpp
[group("apps")]
llama-cpp:
    #!/usr/bin/env -S sudo -- /bin/bash
    set -euo pipefail
    source /usr/lib/catcat-os/funcvar.sh
    umask 0022

    TMP_DIR="/tmp/extra_pkgs"
    BIN_DIR="/usr/local/bin"
    LIBEXEC_DIR="/usr/local/libexec"
    GHPKG_PRERELEASE=1

    rm -rf "${LIBEXEC_DIR}/llama-cpp-vk"

    log "INFO" "Installing and setting up: llama-cpp-vk"
    get_ghpkg --name "llama-cpp-vk" --repo "ggml-org/llama.cpp" \
              --regx 'ubuntu-vulkan-x64\.tar\.gz$' --libexec
    log "INFO" "Operation done for: llama-cpp-vk"
    rm -rf "${TMP_DIR}"

