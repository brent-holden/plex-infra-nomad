#!/usr/bin/env bash

SERVICE="plex"

echo -e "\nThis is where you will put in the Plex claim token so that your Plex server will be associated with your account.\nYou can retrieve that at: https://www.plex.tv/claim/\n"

while [[ -z "${PLEX_TOKEN}" ]]; do
  read -e -p "Enter your Plex claim token: " PLEX_TOKEN
done

consul kv put ${SERVICE}/config/claim_token ${PLEX_TOKEN}

echo -e "\nPlex config is done."
