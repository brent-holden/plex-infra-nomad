#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

PLEX_VER_ONSITE=`curl -s "https://plex.tv/api/downloads/5.json?channel=plexpass" | jq -r '.computer.Linux.version'`

if [ $? -eq 0 ] && [ ${PLEX_VER_ONSITE} != null ]
then
  echo "Found version on plex.tv: ${PLEX_VER_ONSITE}"
  consul kv put plex/config/version ${PLEX_VER_ONSITE}
else
  echo "Caught error trying to fetch version from Plex.tv: Error $?"
fi

