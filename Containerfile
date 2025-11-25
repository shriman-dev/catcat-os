## MAJOR_VERSION arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG BASE_IMAGE_NAME
ARG IMAGE_NAME
ARG MAJOR_VERSION
ARG MAJVER_TAG
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
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

COPY /files /tmp/files
COPY cosign.pub /etc/pki/containers/catcat-os.pub

RUN /tmp/files/scripts/setup.sh && ostree container commit
