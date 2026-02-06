#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

# Container image policy
log "INFO" "Configuring container signing policy"
PROJECT_NAME="${PROJECT_NAME}"
PROJECT_REGISTRY="${PUSH_REGISTRY}"
TEMPLATE_POLICY="${BUILD_SETUP_DIR}/setup_files/policy.json"
COSIGN_PUB_KEY="/etc/pki/containers/${PROJECT_NAME}.pub"
POLICY_FILE="/etc/containers/policy.json"

mkdir -vp /etc/pki/containers /etc/containers/registries.d
cp -vf "/ctx/cosign.pub" "${COSIGN_PUB_KEY}"

# Copy the template policy.json if the file is missing or lacks 'reject' default policy
[[ ! -f "${POLICY_FILE}" ]] && cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"
[[ "$(jq -r '.default[0].type' "${POLICY_FILE}")" == "insecureAcceptAnything" ]] &&
    cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"

jq --arg image_url "${PROJECT_REGISTRY}/${IMAGE_NAME}" \
   --arg cosign_pub_key "${COSIGN_PUB_KEY}" \
   '.transports.docker |=
    { $image_url: [
        {
            "type": "sigstoreSigned",
            "keyPath": $cosign_pub_key,
            "signedIdentity": {
                "type": "matchRepository"
            }
        }
    ] } + .' "${POLICY_FILE}" > "/tmp/POLICY.tmp"

mv -v "/tmp/POLICY.tmp" "${POLICY_FILE}"

echo "docker:
  ${PROJECT_REGISTRY}/${IMAGE_NAME}:
    use-sigstore-attachments: true" > "/etc/containers/registries.d/${PROJECT_NAME}.yaml"

log "INFO" "Container signing policy updated"


set +x
# Sign kernel and kernel modules for secureboot
SBMOK_KEY="${BUILD_ROOT}/sbmok.priv" # Placed by build yaml
SBMOK_DER="/usr/share/${PROJECT_NAME}/certs/${PROJECT_NAME}-mok.der"
SBMOK_CRT="/usr/share/${PROJECT_NAME}/certs/${PROJECT_NAME}-mok.pem"
KERNEL_PATH=(
    $(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -exec test -e "{}/vmlinuz" \; -print)
)

sbsign_modules() {
    local kver="$(basename ${1})" modules_dir="${1}/extra" _kmodules _kmod
    local sign_file="$(find /usr/src/kernels/${kver} -type f -name 'sign-file' -print -quit)"

    if [[ ! -x "${sign_file}" ]]; then
        sign_file="$(find ${1} -type f -name 'sign-file' -print -quit)"
        [[ ! -x "${sign_file}" ]] && sign_file="$(rpm -qal 'kernel*' | grep "${kver}.*sign-file$")"
        [[ ! -x "${sign_file}" ]] && die "Could not find 'sign-file'"
    fi

    sign_module() {
        ${sign_file} sha512 "${SBMOK_KEY}" "${SBMOK_CRT}" "${1}" || die "Failed to sign: ${1}"
    }
    if [[ -d "${modules_dir}" && $(ls -A1 "${modules_dir}" | wc -l) -gt 0 ]]; then
        mapfile -t _kmodules < <(find "${modules_dir}" -type f -name '*\.ko*')
        log "DEBUG" "Signing kernel modules, total count: ${#_kmodules[@]}"
        for _kmod in "${_kmodules[@]}"; do
            case "${_kmod}" in
                *.ko)
                    sign_module "${_kmod}"
                    ;;
                *.ko.bz*)
                    bzip2 --quiet --force --decompress "${_kmod}"
                    sign_module "${_kmod%.bz*}"
                    bzip2 --quiet --force --best "${_kmod%.bz*}"
                    ;;
                *.ko.gz)
                    gzip --quiet --force --decompress "${_kmod}"
                    sign_module "${_kmod%.gz}"
                    gzip --quiet --force --best "${_kmod%.gz}"
                    ;;
                *.ko.xz)
                    xz --quiet --force --decompress "${_kmod}"
                    sign_module "${_kmod%.xz}"
                    xz --quiet --force --check=crc32 "${_kmod%.xz}"
                    ;;
                *.ko.zst)
                    zstd --quiet --force --decompress --rm "${_kmod}"
                    sign_module "${_kmod%.zst}"
                    zstd --quiet --force --rm "${_kmod%.zst}"
                    ;;
            esac
        done
    fi
}

if [[ -f "${SBMOK_KEY}" && -f "${BUILD_ROOT}/sbmok.der" ]]; then
    log "INFO" "Signing kernel and kernel modules with secureboot keys"

    mkdir -vp "$(dirname ${SBMOK_DER})" "/etc/pki/akmods/certs"
    cp -vf "${BUILD_ROOT}/sbmok.der" "${SBMOK_DER}"
    cp -vf "${SBMOK_DER}" "/etc/pki/akmods/certs"/

    openssl x509 -inform DER -in "${SBMOK_DER}" -outform PEM -out "${SBMOK_CRT}"
    [[ ! -f "${SBMOK_CRT}" ]] && die "Failed to create PEM certificate"

    if [[ "${#KERNEL_PATH[@]}" -gt 1 ]]; then
        log "WARN" "Multiple kernel versions found"
        log "WARN" "Single kernel recommended for efficient secureboot signing"
    elif [[ "${#KERNEL_PATH[@]}" -eq 0 ]]; then
        die "Failed to find kernel"
    fi

    for kernel_path in "${KERNEL_PATH[@]}"; do
        kernel_ver="$(basename ${kernel_path})"
        vmlinuz_image="${kernel_path}/vmlinuz"
        sbsign --key  "${SBMOK_KEY}" \
               --cert "${SBMOK_CRT}" \
               --output "${vmlinuz_image}" \
                        "${vmlinuz_image}" || die "Failed to sign: ${vmlinuz_image}"
        sbsign_modules "${kernel_path}"
        log "DEBUG" "Verifying signature for kernel version: ${kernel_ver}"
        sbverify --list "${vmlinuz_image}"
    done
    log "INFO" "Successfully signed kernel and kernel modules"
fi
