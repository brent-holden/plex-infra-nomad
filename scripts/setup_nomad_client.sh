#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Nomad Client ###\n\n"

echo "Configuring repos and installing packages"
yum install -y yum-utils git golang make

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum install -y nomad

cp ${BASH_SOURCE%/*}/../config/nomad/client.hcl /etc/nomad.d/nomad.hcl

mkdir -p ${NOMAD_PLUGIN_DIR}
mkdir -p ~/Code && cd $_
git clone https://github.com/Roblox/nomad-driver-containerd.git nomad-driver-containerd && cd $_
make
cp containerd-driver ${NOMAD_PLUGIN_DIR}
chown -R nomad.nomad ${NOMAD_PLUGIN_DIR}

# Enable containerd
echo "Enabling and starting containerd"
systemctl enable --now containerd

# Enable Nomad
echo "Enabling and starting Nomad"
systemctl enable --now nomad

# Setup cronjob
echo "Copying containerd cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-containerd ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-containerd
systemctl restart crond

echo "Done setting up Nomad client"
