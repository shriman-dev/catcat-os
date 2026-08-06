#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -euo pipefail

#"kernel-devel-matched-$(rpm -q 'kernel' --queryformat '%{VERSION}')"
KER_DEVEL=(
    "kernel-headers"
    "${CUSTOM_KERNEL:-kernel}-devel"
    "${CUSTOM_KERNEL:-kernel}-devel-matched"
)

cachy_kernel() {
    local ker_pkgs=(
        "kernel-cachyos"
        "kernel-cachyos-devel-matched"
        "kernel-cachyos-core"
        "kernel-cachyos-modules"
        "kernel-headers"
    )
    local addons=(
        "scx-scheds"
        "scx-tools"
        "scx-manager"
    )
    # Cachy copr
    dnf5 -y copr enable "bieszczaders/kernel-cachyos"

    # Disable build crahsing scriptlets
#    printf '%s\n' '#!/bin/sh' 'exit 0' | \
#        tee /usr/lib/kernel/install.d/{05-rpmostree,50-dracut}.install

    dnf5 -y clean dbcache
    dnf5 -y --setopt=tsflags=noscripts install "${ker_pkgs[@]}"
    dnf5 -y install "${addons[@]}"
    dnf5 -y versionlock add "${ker_pkgs[@]}"

    # Post kernel install setup
    depmod -a "$(rpm -q "${CUSTOM_KERNEL}" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n')"

    # NOTE: Do not disable custom kernel copr/repo to support building down stream images
    # Disable cachy copr
#    dnf5 -y copr disable "bieszczaders/kernel-cachyos"
}

brief_trace
case "${1}" in
    add)
        if [[ -n "${CUSTOM_KERNEL:-}" ]]; then
            log "INFO" "Installing custom kernel: ${CUSTOM_KERNEL}"
            # Exclude standard kernel pkgs to prevent conflicts
            dnf5 -y config-manager setopt \
                "*fedora*".exclude="kernel-core* kernel-modules* kernel-uki-virt-*"
            if [[ "${CUSTOM_KERNEL}" == "kernel-cachyos" ]]; then
                cachy_kernel
            fi
            log "INFO" "Custom kernel installed successfully: ${CUSTOM_KERNEL}"
        else
            log "INFO" "Adding version lock to standard kernel"
            dnf5 -y install kernel-headers kernel-devel-matched
            dnf5 -y versionlock add \
                kernel kernel-core kernel-modules \
                kernel-modules-core kernel-modules-extra
        fi
        ;;
    remove-devel)
        log "INFO" "Removing kernel devel packages..."
        dnf5 -y remove "${KER_DEVEL[@]}"
        ;;
    *)
        die "Unknown argument: ${1}"
        ;;
esac
brief_trace
