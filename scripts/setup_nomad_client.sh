#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Nomad Client ###\n\n"

sudo yum install -y yum-utils git golang
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install -y nomad
sudo cp ${BASH_SOURCE%/*}/../config/nomad/client.hcl /etc/nomad.d/nomad.hcl

mkdir -p ${NOMAD_PLUGIN_DIR}
mkdir -p ~/Code && cd $_
git clone https://github.com/hashicorp/nomad-driver-podman.git nomad-driver-podman && cd $_
./build.sh
cp nomad-driver-podman ${NOMAD_PLUGIN_DIR}
chown -R nomad.nomad ${NOMAD_PLUGIN_DIR}

# Enable podman remote and socket
echo "Enabling podman remote and socket"
systemctl enable --now podman.service
systemctl enable --now podman.socket
systemctl enable --now io.podman.socket

# Enable systemd
echo "Enabling and starting Nomad"
sudo systemctl enable --now nomad

echo "Done setting up Nomad client"
