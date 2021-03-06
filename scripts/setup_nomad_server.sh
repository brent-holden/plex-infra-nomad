#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Nomad Server ###\n\n"

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

yum install -y nomad
cp ${BASH_SOURCE%/*}/../config/nomad/server.hcl /etc/nomad.d/nomad.hcl

mkdir -p ${NOMAD_PLUGIN_DIR}
mkdir -p ~/Code && cd $_
git clone https://github.com/Roblox/nomad-driver-containerd.git nomad-driver-containerd && cd $_
make
cp containerd-driver ${NOMAD_PLUGIN_DIR}
chown -R nomad.nomad ${NOMAD_PLUGIN_DIR}

# Enable systemd
echo "Enabling and starting Nomad"
systemctl enable --now nomad

echo "Done setting up Nomad server"
