#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

function usage() {

echo "
Usage: update_containers_consul_notify.sh [options]

  This script will pull containers and update the Consul key assigned. The script will ignore
  the service if the <service>/config/auto_update key is set to false.

  The interaction with containerd will require you to use sudo while running this script, or
  it will need to be run as root.

Options:

  -f

      This will override the setting on the auto_update key and force the service container to be updated

  -h
      Prints this useful help dialog

Example:

  update_containers_consul_notify.sh -f
" >&2
}

FORCE=false

while getopts hf FLAG
do
  case "${FLAG}" in
    f)
      FORCE=true;;
    h)
      usage
      exit 0;;
  esac
done

for SERVICE in "${!SERVICES[@]}"
do
  IMG_AND_RELEASE=${SERVICES[${SERVICE}]}
  IMAGE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $1 }')
  RELEASE=$(echo ${IMG_AND_RELEASE} | awk -F ':' '{ print $2 }' | awk -F ',' '{print $1}')
  UPDATE=$(consul kv get ${SERVICE}/config/auto_update)

  if [[ ${UPDATE} == true || ${FORCE} == true ]]; then
    echo -e "\nGot auto update configuration for ${SERVICE} from Consul. Here we go."

    # Pull defined image
    echo "Pulling ${IMAGE}:${RELEASE}"
    ctr image pull ${IMAGE}:${RELEASE}

    # Get image Digest
    DIGEST=$(ctr image ls | grep "${IMAGE}:${RELEASE}" | awk -F ' ' '{print $3}')

    echo "Setting initial key for ${SERVICE}/config/image_digest as ${DIGEST}"
    consul kv put ${SERVICE}/config/image_digest ${DIGEST}
  else
    echo "${SERVICE} auto_update key set to ${UPDATE}. Not updating"
  fi

done
