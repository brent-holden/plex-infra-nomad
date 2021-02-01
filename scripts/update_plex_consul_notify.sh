#!/usr/bin/env bash

#PLEX_VER_IN_USE=`curl -s -H "Content-type: application/json" -H "Accept: application/json" -H "X-Plex-Token: Qq9YyApAKHyzkptsS2_g" http://localhost:32400/ | jq -r '.MediaContainer.version'`
PLEX_VER_ONSITE=`curl -s "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=Qq9YyApAKHyzkptsS2_g" | jq -r '.computer.Linux.version'`

#echo "Found version on system: $PLEX_VER_IN_USE"
#echo "Found version on site: $PLEX_VER_ONSITE"

consul kv put pms-docker/config/version $PLEX_VER_ONSITE

