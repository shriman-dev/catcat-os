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

sign_fail() { die "Failed to sign: ${1}"; }

sbsign_extra_modules() {
    local kernel_path="${1}" kernel_ver="$(basename ${kernel_path})"
    local extra_modules module
    local sign_file="$(find ${kernel_path} -type f -name 'sign-file' -print -quit)"

    if [[ ! -x "${sign_file}" ]]; then
        sign_file="$(find /usr/src/kernel*/"${kernel_ver}" -type f -name 'sign-file' -print -quit)"
        [[ ! -x "${sign_file}" ]] && die "Could not find 'sign-file'"
    fi

    mapfile -t extra_modules < <(find "${kernel_path}/extra" -type f -name '*\.ko*')

    log "DEBUG" "Signing kernel modules, total count: ${#extra_modules[@]}"
    for module in "${extra_modules[@]}"; do
        case "${module}" in
            *.ko)
                ${sign_file} sha512 \
                    "${SBMOK_KEY}" "${SBMOK_CRT}" "${module}" || sign_fail "${module}"
                ;;
            *.ko.gz)
                gzip --quiet --force --decompress "${module}"
                ${sign_file} sha512 \
                    "${SBMOK_KEY}" "${SBMOK_CRT}" "${module%.gz}" || sign_fail "${module}"
                gzip --quiet --force --best "${module%.gz}"
                ;;
            *.ko.xz)
                xz --quiet --force --decompress "${module}"
                ${sign_file} sha512 \
                    "${SBMOK_KEY}" "${SBMOK_CRT}" "${module%.xz}" || sign_fail "${module}"
                xz --quiet --force --check=crc32 "${module%.xz}"
                ;;
            *.ko.zst)
                zstd --quiet --force --decompress --rm "${module}"
                ${sign_file} sha512 \
                    "${SBMOK_KEY}" "${SBMOK_CRT}" "${module%.zst}" || sign_fail "${module}"
                zstd --quiet --force --rm "${module%.zst}"
                ;;
        esac
    done
}

if [[ -f "${SBMOK_KEY}" && -f "${BUILD_ROOT}/sbmok.der" ]]; then
    log "INFO" "Signing kernel and kernel modules with secureboot keys"

    mkdir -vp "$(dirname ${SBMOK_DER})"
    cp -vf "${BUILD_ROOT}/sbmok.der" "${SBMOK_DER}"
    cp -vf "${SBMOK_DER}" "/etc/pki/akmods/certs"/

    openssl x509 -inform DER -in "${SBMOK_DER}" -outform PEM -out "${SBMOK_CRT}"
    [[ ! -f "${SBMOK_CRT}" ]] && die "Failed to create PEM certificate"

    if [[ "${#KERNEL_PATH[@]}" -gt 1 ]]; then
        log "WARN" "Multiple kernel versions found"
        log "WARN" "Single kernel recommended for faster secureboot signing"
    elif [[ "${#KERNEL_PATH[@]}" -eq 0 ]]; then
        die "Failed to find kernel"
    fi

    for kernel_path in "${KERNEL_PATH[@]}"; do
        kernel_ver="$(basename ${kernel_path})"
        vmlinuz_image="${kernel_path}/vmlinuz"
        sbsign --key  "${SBMOK_KEY}" \
               --cert "${SBMOK_CRT}" \
               --output "${vmlinuz_image}" \
                        "${vmlinuz_image}" || sign_fail "${vmlinuz_image}"
        sbsign_extra_modules "${kernel_path}"
        log "DEBUG" "Verifying signature for kernel version: ${kernel_ver}"
        sbverify --list "${vmlinuz_image}"
    done
    log "INFO" "Successfully signed kernel and kernel modules"
fi
