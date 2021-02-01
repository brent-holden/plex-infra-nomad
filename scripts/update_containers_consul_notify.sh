#!/usr/bin/env bash

for IMAGE in `podman ps | awk -F ' ' '{print $2}' | grep -v ID`
do
  # get image Id
  ID=`podman inspect --format "{{.Id}}" $IMAGE`
  
  # get consul kv key
  KEY=`echo $IMAGE | awk -F '/' '{print $3}' | awk -F ':' '{print $1}'`

  echo "Writing: $KEY/config/image as $IMAGE"
  consul kv put $KEY/config/image $IMAGE

  echo "Writing: $KEY/config/image_id as $ID"
  consul kv put $KEY/config/image_id $ID
done
