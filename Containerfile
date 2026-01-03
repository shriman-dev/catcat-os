ARG BASE_IMAGE_NAME
ARG IMAGE_NAME
ARG ALT_TAG
ARG MAJOR_VERSION
ARG TAG_VER
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY / /

### BASE IMAGE
FROM ${BASE_IMAGE_NAME}:${TAG_VER} AS catcat-os

ARG BASE_IMAGE_NAME
ARG IMAGE_NAME
ARG ALT_TAG
ARG MAJOR_VERSION
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

ENV BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ENV IMAGE_NAME="${IMAGE_NAME}"
ENV ALT_TAG="${ALT_TAG}"
ENV MAJOR_VERSION="${MAJOR_VERSION}"
ENV DATESTAMP="${DATESTAMP}"
ENV TIMESTAMP="${TIMESTAMP}"
ENV COMMIT_SHA="${COMMIT_SHA}"

### MODIFICATIONS
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/files/scripts/00-setup.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
