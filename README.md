# Meow

## ISO

Download ISOs from latest release [here](https://github.com/shriman-dev/catcat-os/releases/latest).

Or

You can generate an ISO with the instructions available [here](https://blue-build.org/how-to/generate-iso/).

## Rebase

To rebase an existing atomic Fedora installation to the latest build:
  
  First rebase to the unsigned image, to get the proper signing keys then reboot and rebase to the signed image
  ```
  sudo bootc switch --enforce-container-sigpolicy ghcr.io/shriman-dev/catcat-os:latest
  ```
  ```
  systemctl reboot
  ```
  For Nvdia GPUs:
  ```
  sudo bootc switch --enforce-container-sigpolicy ghcr.io/shriman-dev/catcat-os-nv:latest
  ```
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```
cosign verify --key "https://raw.githubusercontent.com/shriman-dev/catcat-os/refs/heads/main/cosign.pub" ghcr.io/shriman-dev/catcat-os
```

## Fix pub key issue
```
sudo sh -c "curl https://raw.githubusercontent.com/shriman-dev/catcat-os/refs/heads/main/cosign.pub > /etc/pki/containers/catcat-os.pub" &&
sudo sed -i.bak "s#/usr/etc/pki/containers/catcat-os.pub#/etc/pki/containers/catcat-os.pub#" /etc/containers/policy.json
```
