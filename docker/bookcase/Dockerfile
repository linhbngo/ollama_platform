# FROM rockylinux:9.3-minimal
FROM --platform=linux/amd64 interactive_book:base AS stage-amd64

FROM --platform=linux/arm64 interactive_book:base AS stage-arm64

ARG TARGETARCH

FROM stage-${TARGETARCH} AS final
USER student

COPY . /home/student/build
RUN sudo chmod -R 755 /home/student/build/*.sh && /home/student/build/install.sh && sudo rm -rf /home/student/build
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
