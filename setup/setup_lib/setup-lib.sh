#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SCRIPT_DIR}/funcvar.sh"

after_cleanup() {
    rm -vf /var/log/dnf*.log
    find /boot /tmp -mindepth 1 -delete
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
        dnf5 -y config-manager setopt "terra*.enabled=0"
        dnf5 -y config-manager setopt \
                "*terra*.exclude=nerd-fonts topgrade scx-* python3-protobuf zlib-devel"
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
    rm -vf /etc/yum.repos.d/_copr_ublue-os-akmods.repo

    local copr
    for copr in "${copr_list[@]}"; do
        dnf5 -y copr disable "${copr}"
    done
}

# SC2153 - Possible Misspelling: MYVARIABLE may not be assigned
# shellcheck disable=SC2153
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
    )
    [[ -n "${COPR_LIST[*]}" ]] && copr_list+=("${COPR_LIST[@]}")

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
    local operation="${1}" dnf_cmd; shift

    dnf_cmd=("dnf5" "-y")

    [[ $# -eq 0 ]] && die "No argument provided"
    while [[ $# -gt 0 ]]; do
        case ${1} in
            repo)
                dnf_cmd+=(
                    "--enable-repo=${2}"
                    "${operation}"
                )
                shift 2
                ;;
            from-repo)
                dnf_cmd+=(
                    "--enable-repo=${2}"
                    "${operation}"
                    "--from-repo=${2}"
                )
                shift 2
                ;;
            weak-deps)
                dnf_cmd+=(
                    "--setopt=install_weak_deps=True"
                )
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    brief_trace
    "${dnf_cmd[@]}" "$@"
    brief_trace
}

# shellcheck disable=SC2153
pkgs_install() {
    local pkgs_type="${1}" pkg dnf_pkgs=() external_pkgs=() rpm_repos _rpm_repos; shift
    rpm_repos=(
        "terra"
        "terra-extras"
        "${RPM_REPOS[@]}"
    )
    [[ -n "${RPM_REPOS[*]}" ]] && rpm_repos+=("${RPM_REPOS[@]}")
    _rpm_repos="$(tr ' ' ',' <<< "${rpm_repos[@]}")"

    for pkg in "$@"; do
        { [[ "${pkg}" == ++* ]] && external_pkgs+=("${pkg#++}"); } || dnf_pkgs+=("${pkg}")
    done

    if [[ -n "${dnf_pkgs[*]}" ]]; then
        log "INFO" "Installing ${pkgs_type^} RPM Package(s)"
        dnf_action install repo "${_rpm_repos}" "${dnf_pkgs[@]}"
    fi
    if [[ -n "${external_pkgs[*]}" ]]; then
        log "INFO" "Installing ${pkgs_type^} External Package(s)"
        brief_trace
        "${SCRIPT_DIR}"/pkgs-external.sh "${external_pkgs[@]}"
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


