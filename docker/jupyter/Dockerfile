# FROM rockylinux:9.3-minimal
FROM --platform=linux/amd64 ollama_app:base AS stage-amd64

FROM --platform=linux/arm64 ollama_app:base AS stage-arm64

ARG TARGETARCH

FROM stage-${TARGETARCH} AS final
USER root

COPY . /build
RUN sudo chmod -R 755 /build/*.sh && /build/install.sh && sudo rm -rf /build
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
