## MAJOR_VERSION arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG MAJOR_VERSION
ARG IS_NVIDIA
ARG IMAGE_NAME

## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/bazzite-gnome${IS_NVIDIA}:${MAJOR_VERSION} AS ${IMAGE_NAME}

ARG IMAGE_NAME
ARG MAJOR_VERSION
ENV IMAGE_NAME="${IMAGE_NAME}"
ENV MAJOR_VERSION="${MAJOR_VERSION}"

COPY /files /tmp/files
COPY cosign.pub /etc/pki/containers/catcat-os.pub

RUN /tmp/files/scripts/setup.sh && \
    ostree container commit
