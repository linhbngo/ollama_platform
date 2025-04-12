#!/bin/bash

set -e

log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

ARCHTYPE=`uname -m`
GOSU_VERSION=${GOSU_VERSION:-1.12}

log_info "Base image"

source /build/base.config

#------------------------
# Install base image packages
#------------------------

dnf update -y
dnf install -y \
    openssh-server \
    openssh-clients \
    sudo \
    epel-release \
    wget \
    vim \
    openldap-clients \
    sssd \
    sssd-tools \
    sudo \
    authselect \
    openssl \
    bash-completion \
    python3 \
    python3-pip \
    python3-devel \
    tar \
    perl \
    zlib-devel

dnf module -y enable nodejs:20
dnf module -y install nodejs:20/common

#------------------------
# Generate ssh host keys
#------------------------
log_info "Generating ssh host keys.."
ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
chgrp ssh_keys /etc/ssh/ssh_host_rsa_key
chgrp ssh_keys /etc/ssh/ssh_host_ecdsa_key
chgrp ssh_keys /etc/ssh/ssh_host_ed25519_key

sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

#------------------------------------------
# Install and other Python packages
#------------------------------------------

python3 -m venv /opt/env/python3
source /opt/env/python3/bin/activate
env PIP_ROOT_USER_ACTION=ignore
pip install numpy matplotlib pandas nltk scikit-learn ipykernel mystmd
python -m ipykernel install --name=bookcase --display-name "Python (bookcase)"

#------------------------
# Setup user accounts
#------------------------

idnumber=1001
for uid in $USERS
do
    log_info "Bootstrapping $uid user account.."
    adduser --home-dir /home/$uid --shell /bin/bash --uid $idnumber $uid    
    echo "$uid ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$uid
    chmod 0440 /etc/sudoers.d/$uid
    idnumber=$((idnumber + 1))
done

#------------------------
# Install gosu
#------------------------
log_info "Installing gosu.."

if [[ "${ARCHTYPE}" = "x86_64" ]]; then
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"
elif [[ "${ARCHTYPE}" = "aarch64" ]]; then
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-arm64"
fi

chmod +x /usr/local/bin/gosu
gosu nobody true

log_info "Creating self-signed ssl certs.."
# Generate CA
openssl genrsa -out /etc/pki/tls/ca.key 4096
openssl req -new -x509 -days 3650 -sha256 -key /etc/pki/tls/ca.key -extensions v3_ca -out /etc/pki/tls/ca.crt -subj "/CN=fake-ca"
# Generate certificate request
openssl genrsa -out /etc/pki/tls/private/localhost.key 2048
openssl req -new -sha256 -key /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.csr -subj "/C=US/ST=NY/O=HPC Tutorial/CN=localhost"
# Config for signing cert
cat > /etc/pki/tls/localhost.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:localhost
extendedKeyUsage = serverAuth
EOF
# Sign cert request and generate cert
openssl x509 -req -CA /etc/pki/tls/ca.crt -CAkey /etc/pki/tls/ca.key -CAcreateserial \
  -in /etc/pki/tls/certs/localhost.csr -out /etc/pki/tls/certs/localhost.crt \
  -days 365 -sha256 -extfile /etc/pki/tls/localhost.ext
# Add CA to trust store
cp /etc/pki/tls/ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

dnf clean all
rm -rf /var/cache/dnf

cp /build/entrypoint.sh /usr/local/bin/entrypoint.sh
chmod 755 /usr/local/bin/entrypoint.sh

cp -R /build/home/ /opt/
