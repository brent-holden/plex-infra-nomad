#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Nomad Client and Server ###\n\n"

echo "Configuring repos and installing packages"
yum install -y yum-utils git golang make

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum install -y nomad

cp ${BASH_SOURCE%/*}/../config/nomad/allinone.hcl /etc/nomad.d/nomad.hcl

# Enable Nomad
echo "Enabling and starting Nomad"
systemctl enable --now nomad

# Setup cronjob
echo "Copying docker cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-docker ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-docker
systemctl restart crond

echo "Done setting up Nomad client and server"
