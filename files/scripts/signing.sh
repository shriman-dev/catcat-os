#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p /etc/containers
mkdir -p /etc/pki/containers
mkdir -p /etc/containers/registries.d/

TEMPLATE_POLICY="${SCRIPT_DIR}/setup-files/policy.json"


if ! [ -f "/etc/pki/containers/catcat-os.pub" ]; then
  echo "ERROR: Cannot find 'catcat-os.pub' image key in '/etc/pki/containers/'"
  exit 1
fi

if rpm -q ublue-os-signing &>/dev/null; then
  if ! [ -d "/usr/etc/containers/" ]; then
    mkdir -p "/usr/etc/containers/"
  fi
  POLICY_FILE="/usr/etc/containers/policy.json"
else
  POLICY_FILE="/etc/containers/policy.json"
fi

# If there is no policy.json file, then copy the template policy
if ! [ -f "${POLICY_FILE}" ]; then
  cp "${TEMPLATE_POLICY}" "${POLICY_FILE}"
fi

# If the already existing policy.json file doesn't have 'reject' as default policy,
# then signing is effectively disabled & template policy.json should be copied in that case also
if [[ "$(jq -r '.default[0].type' "${POLICY_FILE}")" == "insecureAcceptAnything" ]]; then
  cp "${TEMPLATE_POLICY}" "${POLICY_FILE}"
fi

# ${IMAGE_NAME} is exported by build-image.yml file
jq --arg image_name "${IMAGE_NAME}" \
   '.transports.docker |= 
    { ("ghcr.io/shriman-dev/" + $image_name): [
        {
            "type": "sigstoreSigned",
            "keyPath": "/etc/pki/containers/catcat-os.pub",
            "signedIdentity": {
                "type": "matchRepository"
            }
        }
    ] } + .' "${POLICY_FILE}" > "/tmp/POLICY.tmp"

cat /tmp/POLICY.tmp

mv "/tmp/POLICY.tmp" "${POLICY_FILE}"

echo 'docker:
  ghcr.io/shriman-dev:
    use-sigstore-attachments: true' > /etc/containers/registries.d/catcat-os.yaml


