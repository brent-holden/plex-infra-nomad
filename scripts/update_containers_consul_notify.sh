#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

for SERVICE in "${!SERVICES[@]}"
do
  IMG_AND_RELEASE=${SERVICES[${SERVICE}]}
  IMAGE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $1 }')
  RELEASE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $2 }' | awk -F ',' '{print $1}')
  UPDATE=$(consul kv get ${SERVICE}/config/auto_update)

  if [[ ${UPDATE} == true ]]; then
    echo -e "\nGot auto update configuration for ${SERVICE} from Consul. Here we go."

    # Pull defined image
    echo "Pulling ${IMAGE}:${RELEASE}"
    ctr image pull ${IMAGE}:${RELEASE}

    # Get image Id
    DIGEST=$(ctr image ls | grep "${IMAGE}:${RELEASE}" | awk -F ' ' '{print $3}')

    echo "Setting initial key for ${SERVICE}/config/image_digest as ${DIGEST}"
    consul kv put ${SERVICE}/config/image_digest ${DIGEST}
  else
    echo "${SERVICE} auto_update key set to ${UPDATE}. Not updating"
  fi

done
