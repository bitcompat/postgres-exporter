# syntax=docker/dockerfile:1.4

FROM golang:1.19-bullseye AS golang-builder

ARG PACKAGE=postgres_exporter
ARG TARGET_DIR=postgres-exporter
# renovate: datasource=github-releases depName=prometheus-community/postgres_exporter
ARG VERSION=0.11.1
ARG REF=v${VERSION}

ARG TARGETARCH

COPY --link prebuildfs /
RUN mkdir -p /opt/bitnami
RUN --mount=type=cache,target=/root/.cache/go-build <<EOT /bin/bash
    set -ex

    rm -rf ${PACKAGE} || true
    mkdir -p ${PACKAGE}
    git clone -b "${REF}" https://github.com/prometheus-community/postgres_exporter ${PACKAGE}

    pushd ${PACKAGE}
    GOOS=linux GOARCH=$TARGETARCH make build

    ls -lah
    mkdir -p /opt/bitnami/${TARGET_DIR}/licenses
    mkdir -p /opt/bitnami/${TARGET_DIR}/bin
    cp -f LICENSE /opt/bitnami/${TARGET_DIR}/licenses/${PACKAGE}-${VERSION}.txt
    cp -f ${PACKAGE} /opt/bitnami/${TARGET_DIR}/bin/${PACKAGE}
    popd

    rm -rf ${PACKAGE}
EOT


FROM docker.io/bitnami/minideb:bullseye as stage-0

ARG TARGETARCH
ENV HOME="/" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    APP_VERSION="0.11.1" \
    BITNAMI_APP_NAME="postgres-exporter" \
    PATH="/opt/bitnami/postgres-exporter/bin:$PATH"

LABEL org.opencontainers.image.ref.name="0.11.1-debian-11-r1" \
      org.opencontainers.image.title="postgres-exporter" \
      org.opencontainers.image.version="0.11.1"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
COPY --link --from=golang-builder /opt/bitnami/ /opt/bitnami/
RUN install_packages ca-certificates curl gzip procps tar

EXPOSE 9187

WORKDIR /opt/bitnami/postgres-exporter
USER 1001
ENTRYPOINT [ "postgres_exporter" ]
