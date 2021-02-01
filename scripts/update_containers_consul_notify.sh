#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

for SERVICE in "${!SERVICES[@]}"
do
  IMAGE=${SERVICES[${SERVICE}]}

  # pull new image
  sudo podman pull ${IMAGE}
  
  # get image Id
  ID=`sudo podman inspect --format "{{.Id}}" ${IMAGE}`
 
  # echo "Writing: ${SERVICE}/config/image as ${IMAGE}"
  consul kv put ${SERVICE}/config/image ${IMAGE}

  # echo "Writing: ${SERVICE}/config/image_id as $ID"
  consul kv put ${SERVICE}/config/image_id $ID
done
