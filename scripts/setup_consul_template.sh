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

echo -e "\n### Done setting up Consul Template"

