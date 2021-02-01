#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Consul Agent ###\n\n"

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install -y consul-enterprise

sudo cp ${BASH_SOURCE%/*}/../config/consul/agent.hcl /etc/consul.d/consul.hcl

# Enable systemd
echo "Enabling and starting Consul"
sudo systemctl enable --now consul

echo "Done setting up Consul"

