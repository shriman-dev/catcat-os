#!/usr/bin/env bash
source "${BUILD_SCRIPT_LIB}"
set -ouex pipefail

log "INFO" "Configuring container signing policy and placing cosign pub key"

PROJECT_NAME="${PROJECT_NAME}"
PROJECT_REGISTRY="${PUSH_REGISTRY}"
TEMPLATE_POLICY="${BUILD_SETUP_DIR}/setup_files/policy.json"
COSIGN_PUB_KEY="/etc/pki/containers/${PROJECT_NAME}.pub"
POLICY_FILE="/etc/containers/policy.json"

mkdir -vp /etc/pki/containers /etc/containers/registries.d
cp -vf "${BUILD_SETUP_DIR}/setup_files/cosign.pub" "${COSIGN_PUB_KEY}"

# TODO: Add secure boot signing in non ublue images

# Copy the template policy.json if the file is missing or lacks 'reject' default policy
[[ ! -f "${POLICY_FILE}" ]] && cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"
[[ "$(jq -r '.default[0].type' "${POLICY_FILE}")" == "insecureAcceptAnything" ]] &&
    cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"

jq --arg image_name "${IMAGE_NAME}" \
   --arg project_registry "${PROJECT_REGISTRY}" \
   --arg cosign_pub_key "${COSIGN_PUB_KEY}" \
   '.transports.docker |=
    { ($project_registry + "/" +  $image_name): [
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

log "INFO" "Updated container signing policy"

