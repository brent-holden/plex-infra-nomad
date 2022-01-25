#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up docker ###\n\n"
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

# Enable docker
echo "Enabling and starting docker.."
systemctl enable --now docker

echo "Copying docker cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-docker ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-docker
systemctl restart crond

echo "Done setting up docker!"
