#!/usr/bin/env bash
set -oue pipefail
source /usr/lib/catcat/funcvar.sh

TMP_DIR="/tmp/catcat_extra_pkgs"
mkdir -vp "${TMP_DIR}"

eza() {
    local eza_repo="https://github.com/eza-community/eza"
    local eza_tar="${TMP_DIR}/eza.tar.gz"
    curl -Lo "${eza_tar}" "${eza_repo}/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    log "INFO" "Installing eza"
    mkdir -vp "${eza_tar}.extract"
    tar -xvf "${eza_tar}" -C "${eza_tar}.extract"
    cp -dvf "${eza_tar}.extract/eza" /usr/bin/
    chmod -v +x /usr/bin/eza
    rm -rf "${eza_tar}" "${eza_tar}.extract"
    log "INFO" "Done."
}
eza

btdu() {
    local btdu_repo="https://github.com/CyberShadow/btdu"
    log "INFO" "Installing btdu"
    curl -Lo "/usr/bin/btdu" "${btdu_repo}/releases/latest/download/btdu-static-x86_64"
    chmod -v +x "/usr/bin/btdu"
    log "INFO" "Done."
}
btdu

buttersnap() {
    local buttersnap_repo="https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main"
    log "INFO" "Installing btdu"
    curl -Lo "/usr/bin/buttersnap.sh" "${buttersnap_repo}/buttersnap.sh"
    chmod -v +x "/usr/bin/buttersnap.sh"
    curl -Lo "/usr/bin/buttercopy.sh" "${buttersnap_repo}/buttercopy.sh"
    chmod -v +x "/usr/bin/buttercopy.sh"
    log "INFO" "Done."
}
buttersnap

hblock() {
    local hblock_repo="https://raw.githubusercontent.com/hectorm/hblock/refs/heads/master"
    log "INFO" "Installing hblock"
    curl -Lo "/usr/bin/hblock" "${hblock_repo}/hblock"
    chmod -v +x "/usr/bin/hblock"
    log "INFO" "Done."
}
hblock

bandwhich() {
    local bandwhich_repo="https://api.github.com/repos/imsnif/bandwhich"
    local bandwhich_tar="${TMP_DIR}/bandwhich.tar.gz"
    log "INFO" "Installing bandwhich"
    curl -Lo "${bandwhich_tar}" $(curl -s -X GET "${bandwhich_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.tar.gz"' | cut -d '"' -f4)
    mkdir -vp "${bandwhich_tar}.extract"
    tar -xvf "${bandwhich_tar}" -C "${bandwhich_tar}.extract"
    cp -dvf "${bandwhich_tar}.extract/bandwhich" "/usr/bin"/
    chmod -v +x /usr/bin/bandwhich
    rm -rf "${bandwhich_tar}" "${bandwhich_tar}.extract"
    log "INFO" "Done."
}
bandwhich

gocryptfs() {
    local gocryptfs_repo="https://api.github.com/repos/rfjakob/gocryptfs"
    local gocryptfs_tar="${TMP_DIR}/gocryptfs.tar.gz"
    log "INFO" "Installing gocryptfs"
    curl -Lo "${gocryptfs_tar}" $(curl -s -X GET "${gocryptfs_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*linux-static_amd64.tar.gz"' | cut -d '"' -f4)
    mkdir -vp "${gocryptfs_tar}.extract"
    tar -xvf "${gocryptfs_tar}" -C "${gocryptfs_tar}.extract"
    cp -dvf "${gocryptfs_tar}.extract/gocryptfs" "/usr/bin"/
    chmod -v +x /usr/bin/gocryptfs
    rm -rf "${gocryptfs_tar}" "${gocryptfs_tar}.extract"
    log "INFO" "Done."
}
gocryptfs

llama_cpp() {
    local llama_cpp_repo="https://api.github.com/repos/ggml-org/llama.cpp"
    local llama_cpp_zip="${TMP_DIR}/llama-cpp-vulkan.zip"
    local ulibexec_llama_cpp="/usr/libexec/llama_cpp_vulkan"
    log "INFO" "Installing llama_cpp"
    curl -Lo "${llama_cpp_zip}" $(curl -s -X GET "${llama_cpp_repo}/releases/latest" | grep -i '"browser_download_url": "[^"]*ubuntu-vulkan-x64.zip"' | cut -d '"' -f4)
    mkdir -vp "${llama_cpp_zip}.extract" "${ulibexec_llama_cpp}"
    cd "${llama_cpp_zip}.extract"
    unzip "${llama_cpp_zip}"
    cd -
    mv -v "${llama_cpp_zip}.extract/build/bin" "${ulibexec_llama_cpp}"/
    chmod -v +x "${ulibexec_llama_cpp}/bin"/llama-{batched-bench,bench,cli,imatrix,gguf-split,mtmd-cli,quantize,run,server,tokenize,tts}
    ln -svf "${ulibexec_llama_cpp}/bin"/llama-{batched-bench,bench,cli,imatrix,gguf-split,mtmd-cli,quantize,run,server,tokenize,tts} /usr/bin/
    rm -rf "${llama_cpp_zip}" "${llama_cpp_zip}.extract"
    log "INFO" "Done."
}
llama_cpp

yazi() {
    local yazi_repo="https://github.com/sxyazi/yazi"
    local yazi_repo_raw="https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main"
    local yazi_zip="${TMP_DIR}/yazi.zip"
    log "INFO" "Installing yazi"
    curl -Lo "${yazi_zip}" "${yazi_repo}/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    curl -Lo /usr/share/applications/yazi.desktop "${yazi_repo_raw}/assets/yazi.desktop"
    curl -Lo /usr/share/icons/yazi.png "${yazi_repo_raw}/assets/logo.png"

    mkdir -vp "${yazi_zip}.extract"
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
yazi

pipes_sh() {
    local pipes_sh_repo="https://raw.githubusercontent.com/pipeseroni/pipes.sh/refs/heads/master"
    log "INFO" "Installing pipes.sh"
    curl -Lo "/usr/bin/pipes.sh" "${pipes_sh_repo}/pipes.sh"
    chmod -v +x "/usr/bin/pipes.sh"
    log "INFO" "Done."
}
pipes_sh

ascii_image_converter() {
    local ascii_ic_repo="https://github.com/TheZoraiz/ascii-image-converter"
    local ascii_ic_tar="${TMP_DIR}/ascii_ic.tar.gz"
    log "INFO" "Installing ascii-image-converter"
    curl -Lo "${ascii_ic_tar}" "${ascii_ic_repo}/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz"
    mkdir -vp "${ascii_ic_tar}.extract"
    tar -xvf "${ascii_ic_tar}" -C "${ascii_ic_tar}.extract"
    cp -dvf "${ascii_ic_tar}.extract"/*/ascii-image-converter "/usr/bin"/
    chmod -v +x /usr/bin/ascii-image-converter
    rm -rf "${ascii_ic_tar}" "${ascii_ic_tar}.extract"
    log "INFO" "Done."
}
ascii_image_converter

extras() {
    curl -Lo /usr/share/applications/micro.desktop \
        https://raw.githubusercontent.com/zyedidia/micro/refs/heads/master/assets/packaging/micro.desktop
}
extras

rm -rf "${TMP_DIR}"
