# Meow

To rebase an existing atomic Fedora installation to the latest build:
  First rebase to the unsigned image, to get the proper signing keys then reboot and rebase to the signed image
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/shriman-dev/catcat-os:latest
  ```
  ```
  systemctl reboot
  ```
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/shriman-dev/catcat-os:latest
  ```
  For Nvdia GPUs:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/shriman-dev/catcat-os-nv:latest
  ```
  ```
  systemctl reboot
  ```
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/shriman-dev/catcat-os-nv:latest
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/how-to/generate-iso/). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

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
