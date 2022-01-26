#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# This script assumes you have already installed docker
# Use setup_docker.sh to do that

echo -e "\n\n### Setting up Nomad Client ###\n\n"

echo "Configuring repos and installing packages"
yum install -y yum-utils git golang make curl

# Install repositories
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo

yum install -y nomad
yum install -y containernetworking-plugins

# Link the CNI binaries directory so that Nomad works with Consul Connect
mkdir ${OPT_DIR}/cni
ln -sf /usr/libexec/cni ${OPT_DIR}/cni/bin

cp ${BASH_SOURCE%/*}/../config/nomad/client.hcl /etc/nomad.d/nomad.hcl

# Enable Nomad
echo "Enabling and starting Nomad"
systemctl enable --now nomad

# Setup cronjob
echo "Copying docker cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-docker ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-docker
systemctl restart crond

echo "Done setting up Nomad client"
