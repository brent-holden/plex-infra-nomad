#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up containerd ###\n\n"

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io

# Enable containerd
echo "Enabling and starting containerd"
systemctl enable --now containerd

echo "Copying containerd cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-containerd ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-containerd
systemctl restart cron.d

echo "Done setting up containerd!"
