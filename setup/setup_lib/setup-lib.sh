#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/funcvar.sh"

after_cleanup() {
    rm -rvf /var/log/dnf*.log
    rm -rvf /boot/.*
    rm -rvf /boot/*
    rm -rvf /tmp/.*
    rm -rvf /tmp/*
}

enable_rpm_repos() {
    # Preparation
    sed -i 's|^ID=.*|ID="fedora"|' /usr/lib/os-release
    rpm -q dnf5-plugins || dnf5 -y install dnf5-plugins

    local copr
    for copr in "${copr_list[@]}"; do
        dnf5 -y copr enable "${copr}"
    done

    # Always remove cisco repo
    if [[ -f "/etc/yum.repos.d/fedora-cisco-openh264.repo" ]]; then
        rm -vf "/etc/yum.repos.d/fedora-cisco-openh264.repo"
    fi

    # Terra Repo
    if [[ ! -f "/etc/yum.repos.d/terra.repo" ]]; then
        dnf5 -y install --nogpgcheck --repofrompath \
                'terra,https://repos.fyralabs.com/terra$releasever' \
                terra-release{,-extras,-mesa} terra-gpg-keys
#        dnf5 -y install --nogpgcheck --repofrompath \
#                'terra-multimedia,https://repos.fyralabs.com/terra$releasever' \
#                terra-release-multimedia
        dnf5 -y config-manager setopt "terra*".enabled=0
        dnf5 -y config-manager setopt \
                "*terra*".exclude="nerd-fonts topgrade scx-* python3-protobuf zlib-devel"
    fi

    # NVIDIA Repos
    if [[ ! -f "/etc/yum.repos.d/fedora-nvidia.repo" ]]; then
        dnf5 -y config-manager addrepo \
             --from-repofile="https://negativo17.org/repos/fedora-nvidia.repo"
        dnf5 -y config-manager addrepo \
             --from-repofile="https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo"
        dnf5 -y config-manager setopt fedora-nvidia.enabled=0
        dnf5 -y config-manager setopt nvidia-container-toolkit.enabled=0
        dnf5 -y config-manager setopt nvidia-container-toolkit.gpgcheck=1
    fi

    # Negativo17 Multimedia Repo
    if [[ ! -f "/etc/yum.repos.d/fedora-multimedia.repo" ]]; then
        dnf5 -y config-manager addrepo \
             --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
        dnf5 -y config-manager setopt fedora-multimedia.enabled=0
        dnf5 -y config-manager setopt fedora-multimedia.priority=90
    fi

    # Rpmfusion Repo
#    dnf5 -y install \
#    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
#    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

disable_rpm_repos() {
    local repo copr
    for repo in _copr_ublue-os-akmods.repo; do
        sed -i 's/enabled=1/enabled=0/g' "/etc/yum.repos.d/${repo}" || true
    done
    for copr in "${copr_list[@]}"; do
        dnf5 -y copr disable "${copr}"
    done
}

rpm_repos() {
    local action="${1}"
    local copr_list=(
        "bieszczaders/kernel-cachyos-addons"
#        "ublue-os/bazzite"
#        "ublue-os/bazzite-multilib"
#        "ublue-os/staging"
#        "ublue-os/packages"
#        "kylegospo/unl0kr"
#        "atim/starship"
#        "zeno/scrcpy"
#        "atim/lazygit"
        "${COPR_LIST[@]}"
    )

    case "${action}" in
        enable)
            log "INFO" "Adding extra RPM repos"
            brief_trace
            enable_rpm_repos
            brief_trace
            log "INFO" "Added extra repos"
            ;;
        disable)
            log "INFO" "Disabling repos no longer needed"
            brief_trace
            disable_rpm_repos
            brief_trace
            log "INFO" "Disabled unneeded repos"
            ;;
        *) die "Unknown argument: ${action}"
            ;;
    esac
}

dnf_action() {
    local operation="${1}" from_repo="" repo="" weak_deps="False"; shift

    while [[ $# -gt 0 ]]; do
        case ${1} in
            from-repo)
                repo="--enable-repo=${2}"
                from_repo="--from-repo=${2}"
                shift 2
                ;;
            enable-repo)
                repo="--enable-repo=${2}"
                shift 2
                ;;
            weak-deps)
                weak_deps="True"
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    brief_trace
    dnf5 -y clean dbcache
    dnf5 -y --setopt=install_weak_deps="${weak_deps}" \
            ${repo} ${operation} ${from_repo} "$@"
    brief_trace
}

pkgs_install() {
    local pkgs_type="${1}"; shift
    local dnf_pkgs="$(printf '%s\n' "$@" | grep -v '^++')"
    local external_pkgs="$(printf '%s\n' "$@" | sed -n 's|^++||gp')"
    local rpm_repos=(
        "terra"
        "terra-extras"
        "${RPM_REPOS[@]}"
    )
    rpm_repos="$(tr ' ' ',' <<< "${rpm_repos[@]}")"

    if [[ -n "${dnf_pkgs}" ]]; then
        log "INFO" "Installing ${pkgs_type^} RPM Package(s)"
        dnf_action install enable-repo "${rpm_repos}" ${dnf_pkgs}
    fi
    if [[ -n "${external_pkgs}" ]]; then
        log "INFO" "Installing ${pkgs_type^} External Package(s)"
        brief_trace
        "${SCRIPT_DIR}"/pkgs-external.sh ${external_pkgs}
        brief_trace
    fi
    log "INFO" "${pkgs_type^} package(s) installed successfully"
}

kernel_add() {
    ( set -x; "${SCRIPT_DIR}"/pkgs-kernel.sh add )
}

pkgs_hwaccel() {
    ( set -x; "${SCRIPT_DIR}"/pkgs-hwaccel.sh )
}


