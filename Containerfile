ARG PROJECT_NAME
ARG IMAGE_NAME
ARG BASE_IMAGE_URL
ARG PUSH_REGISTRY
ARG MAJOR_VERSION
ARG ALT_TAG
ARG TAG_VER
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY / /

### BASE IMAGE
FROM ${BASE_IMAGE_URL}:${TAG_VER} AS ${PROJECT_NAME}

ARG PROJECT_NAME
ARG IMAGE_NAME
ARG BASE_IMAGE_URL
ARG PUSH_REGISTRY
ARG MAJOR_VERSION
ARG ALT_TAG
ARG DATESTAMP
ARG TIMESTAMP
ARG COMMIT_SHA

ENV PROJECT_NAME="${PROJECT_NAME}"
ENV IMAGE_NAME="${IMAGE_NAME}"
ENV BASE_IMAGE_URL="${BASE_IMAGE_URL}"
ENV PUSH_REGISTRY="${PUSH_REGISTRY}"
ENV MAJOR_VERSION="${MAJOR_VERSION}"
ENV ALT_TAG="${ALT_TAG}"
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
