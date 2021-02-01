#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

#PLEX_VER_IN_USE=`curl -s -H "Content-type: application/json" -H "Accept: application/json" -H "${PLEX_TOKEN}" http://localhost:32400/ | jq -r '.MediaContainer.version'`
PLEX_VER_ONSITE=`curl -s -H "${PLEX_TOKEN}" "https://plex.tv/api/downloads/5.json?channel=plexpass" | jq -r '.computer.Linux.version'`

#echo "Found version on system: ${PLEX_VER_IN_USE}"
#echo "Found version on site: ${PLEX_VER_ONSITE}"

consul kv put plex/config/version ${PLEX_VER_ONSITE}

