FROM --platform=linux/amd64 rockylinux:9.3 AS stage-amd64

FROM --platform=linux/arm64/v8 rockylinux:9.3 AS stage-arm64

ARG TARGETARCH

FROM stage-${TARGETARCH} AS final

USER root

COPY . /build
RUN chmod -R 755 /build/*.sh && /build/install.sh && rm -rf /build
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
