#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

for SERVICE in "${!SERVICES[@]}"
do
  IMG_AND_RELEASE=${SERVICES[${SERVICE}]}
  IMAGE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $1 }')
  RELEASE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $2 }' | awk -F ',' '{print $1}')
  UPDATE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $2 }' | awk -F ',' '{print $2}')


  # Pull defined image into containerd. This must be run as root or under sudo to work
  echo "Pulling ${IMAGE}:${RELEASE}"
  docker pull ${IMAGE}:${RELEASE}

  # Get image SHA256 Digest
  DIGEST=$(ctr image ls | grep "${IMAGE}:${RELEASE}" | awk -F ' ' '{print $3}')

  # Set initial Consul key values
  echo "Setting initial key for ${SERVICE}/config/image as ${IMAGE}"
  consul kv put ${SERVICE}/config/image ${IMAGE}

  echo "Setting initial key for ${SERVICE}/config/release as ${RELEASE}"
  consul kv put ${SERVICE}/config/release ${RELEASE}

  echo "Setting initial key for ${SERVICE}/config/image_digest as ${DIGEST}"
  consul kv put ${SERVICE}/config/image_digest ${DIGEST}

  if [[ ${UPDATE} == "auto_update" ]]; then
    echo "Setting auto_update key set to true"
    consul kv put ${SERVICE}/config/auto_update true
  else
    echo "Setting auto_update key set to false. Key was ${UPDATE}"
    consul kv put ${SERVICE}/config/auto_update false
  fi

done
