ARG BASE_IMAGE_NAME
ARG IMAGE_NAME
ARG MAJOR_VERSION
ARG MAJVER_TAG
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY files /

### BASE IMAGE
FROM ${BASE_IMAGE_NAME}:${MAJVER_TAG} AS catcat-os

ARG BASE_IMAGE_NAME
ARG IMAGE_NAME
ARG MAJOR_VERSION
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA
ENV BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ENV IMAGE_NAME="${IMAGE_NAME}"
ENV MAJOR_VERSION="${MAJOR_VERSION}"
ENV DATESTAMP="${DATESTAMP}"
ENV TIMESTAMP="${TIMESTAMP}"
ENV COMMIT_SHA="${COMMIT_SHA}"

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
        /ctx/scripts/00-setup.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
