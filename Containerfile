ARG PRETTY_NAME
ARG PROJECT_NAME
ARG PROJECT_VENDOR
ARG PROJECT_SOURCE
ARG PROJECT_README
ARG PUSH_REGISTRY
ARG MAJOR_VERSION
ARG CUSTOM_KERNEL
ARG TIMEZONE
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

ARG IMAGE_NAME
ARG BASE_IMAGE
ARG ALT_TAG

### BASE IMAGE
FROM ${BASE_IMAGE}:${MAJOR_VERSION} AS ${IMAGE_NAME}

ARG PRETTY_NAME
ARG PROJECT_NAME
ARG PROJECT_VENDOR
ARG PROJECT_SOURCE
ARG PROJECT_README
ARG PUSH_REGISTRY
ARG MAJOR_VERSION
ARG CUSTOM_KERNEL
ARG TIMEZONE
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

ARG IMAGE_NAME
ARG BASE_IMAGE
ARG ALT_TAG

ARG TZ="${TIMEZONE}"
ARG BUILD_ROOT_DIR="/ctx"
ARG BUILD_SETUP_DIR="${BUILD_ROOT_DIR}/setup"
ARG BUILD_SCRIPT_LIB="${BUILD_SETUP_DIR}/setup_lib/setup-lib.sh"

### MODIFICATIONS
RUN --mount=type=secret,id=sbmok_priv \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,source=./,target=/ctx,rw \
    ${BUILD_SETUP_DIR}/00-setup.sh \
        prep-env \
        cleanup \
        debloat \
        copy-sysfiles \
        pkgs-kernel \
        pkgs-common \
        pkgs-hwaccel \
        pkgs-desktop \
        theming \
        secatcat \
        systemd \
        tweaks-fixes \
        variant \
        image-info \
        signing \
        initramfs \
        post-setup

### LINTING
## Verify final image and contents are correct
RUN --network=none \
    --mount=type=tmpfs,target=/run \
    bootc container lint
