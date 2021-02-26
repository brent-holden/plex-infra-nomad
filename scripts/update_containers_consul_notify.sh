#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

for SERVICE in "${!SERVICES[@]}"
do
  IMGANDREPO=${SERVICES[${SERVICE}]}
  IMAGE=`echo ${IMGANDREPO} | awk -F : '{ print $1 }'`
  RELEASE=`echo ${IMGANDREPO} | awk -F : '{ print $2 }'`

  # pull defined image
  echo "Pulling ${IMAGE}:${RELEASE}"
  podman pull ${IMAGE}:${RELEASE}

  # get image Id
  ID=$(podman inspect --format "{{.Id}}" ${IMAGE}:${RELEASE})
  DIGEST=$(podman inspect --format "{{.Digest}}" ${IMAGE}:${RELEASE})

  # Now write all the values to Consul KV
#  echo "Writing: ${SERVICE}/config/image as ${IMAGE}"
  consul kv put ${SERVICE}/config/image ${IMAGE}

#  echo "Writing: ${SERVICE}/config/release as ${RELEASE}"
  consul kv put ${SERVICE}/config/release ${RELEASE}

#  echo "Writing: ${SERVICE}/config/image_id as ${ID}"
  consul kv put ${SERVICE}/config/image_id ${ID}

#  echo "Writing: ${SERVICE}/config/image_digest as ${DIGEST}"
  consul kv put ${SERVICE}/config/image_digest ${DIGEST}

done
