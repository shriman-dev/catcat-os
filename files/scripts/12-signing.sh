#!/usr/bin/env bash
source /usr/lib/catcat/funcvar.sh
set -ouex pipefail

TEMPLATE_POLICY="${SETUP_DIR}/setup_files/policy.json"
CATCAT_PUB="/etc/pki/containers/catcat-os.pub"
POLICY_FILE="/etc/containers/policy.json"

# TODO: Add secure boot signing in non ublue images

log "INFO" "Configuring container image signing policy and placing catcat-os pub key"

mkdir -vp /etc/pki/containers /etc/containers/registries.d

[[ ! -f "${CATCAT_PUB}" ]] &&
    die "Cannot find '$(basename ${CATCAT_PUB})' image key in: $(dirname ${CATCAT_PUB})"

# If there is no policy.json file, then copy the template policy
[[ ! -f "${POLICY_FILE}" ]] && cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"
# If the already existing policy.json file doesn't have 'reject' as default policy,
# then signing is effectively disabled and template policy.json should be copied in that case also
[[ "$(jq -r '.default[0].type' "${POLICY_FILE}")" == "insecureAcceptAnything" ]] &&
    cp -v "${TEMPLATE_POLICY}" "${POLICY_FILE}"

# ${IMAGE_NAME} is exported by build-image.yml file
jq --arg image_name "${IMAGE_NAME}" \
   '.transports.docker |= 
    { ("ghcr.io/shriman-dev/" + $image_name): [
        {
            "type": "sigstoreSigned",
            "keyPath": "'${CATCAT_PUB}'",
            "signedIdentity": {
                "type": "matchRepository"
            }
        }
    ] } + .' "${POLICY_FILE}" > "/tmp/POLICY.tmp"

mv -v "/tmp/POLICY.tmp" "${POLICY_FILE}"

echo 'docker:
  ghcr.io/shriman-dev:
    use-sigstore-attachments: true' > /etc/containers/registries.d/catcat-os.yaml

log "INFO" "Done."


