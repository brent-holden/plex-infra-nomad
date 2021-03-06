#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

NAME="consul-template"
RELEASE="0.25.2"
PLATFORM="linux_amd64"
DEST="/usr/local/bin"

echo -e "### Setting up Consul Template\n"

echo "Installing unzip"
yum install -y unzip

echo "Downloading ${NAME}_${RELEASE} for ${PLATFORM}"
curl https://releases.hashicorp.com/${NAME}/${RELEASE}/${NAME}_${RELEASE}_${PLATFORM}.zip --output /tmp/${NAME}-${RELEASE}_${PLATFORM}.zip

"Installing ${NAME} to ${DEST}"
unzip -qo /tmp/${NAME}-${RELEASE}_${PLATFORM}.zip -d ${DEST}

echo "Creating consul-template sysconfig file for setting options"
echo "OPTIONS=" > /etc/sysconfig/consul-template

echo "Creating configuration directory ${CONSUL_TEMPLATE_CONF_DIR}"
mkdir -p ${CONSUL_TEMPLATE_CONF_DIR}

echo "Copying over systemd unit files"
cp ${SYSTEMD_SVCFILES_DIR}/consul-template.service ${SYSTEMD_DIR}
systemctl daemon-reload

echo "Enabling consul-template"
systemctl enable --now consul-template

echo -e "\n### Done setting up Consul Template"

