#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up containerd ###\n\n"
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io containernetworking-plugins

# Setup the softlink for containerd to containernetworking-plugins
echo "Soft-linking the containerplugins directory so that containerd can find them.."
mkdir -p /opt/cni
ln -sf /usr/libexec/cni /opt/cni/bin

echo "Setting sysctls for containerd.."
cat <<EOH >> /etc/sysctl.d/50-container
net.ipv4.ip_unprivileged_port_start=0
net.bridge.bridge-nf-call-arptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
EOH

# Enable containerd
echo "Enabling and starting containerd.."
systemctl enable --now containerd

echo "Copying containerd cleaning configuration to /etc/cron.d"
cp ${BASH_SOURCE%/*}/../cron/clean-containerd ${CRON_DIR}
sed -i "s~%%SCRIPT_REPO%%~${REPO_DIR}~" ${CRON_DIR}/clean-containerd
systemctl restart crond

echo "Done setting up containerd!"
