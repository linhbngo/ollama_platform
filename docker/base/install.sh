#!/bin/bash

#------------------------
# Install base image packages
#------------------------

dnf update -y
dnf install -y \
    bash-completion \
    python3 \
    python3-pip \
    python3-devel \
    sudo \
    tar \
    perl \
    zlib-devel

#------------------------------------------
# Install and other Python packages
#------------------------------------------

env PIP_ROOT_USER_ACTION=ignore
pip install --no-cache-dir numpy matplotlib pandas nltk scikit-learn ipykernel lxml

dnf clean all
rm -rf /var/cache/dnf

cp /build/entrypoint.sh /usr/local/bin/entrypoint.sh
chmod 755 /usr/local/bin/entrypoint.sh
