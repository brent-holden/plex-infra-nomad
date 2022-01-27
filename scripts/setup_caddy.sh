#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

SERVICE="caddy"

CADDY_IMAGE=$(echo ${SERVICES[caddy]} | awk -F ',' '{print $1}')

echo -e "\nLet's protect your /downloads directory from uninvited guests."

while [[ -z "${EXTERNAL_USER}" ]]; do
  read -e -p "Enter the a user name for basic auth: " EXTERNAL_USER
done

while [[ -z "${EXTERNAL_PASSWORD}" ]]; do
  read -s -e -p "Enter the password for that user: " EXTERNAL_PASSWORD
done

echo -e "\n\nPulling caddy container to generate our bcrypt password"
HASHED_PASSWORD=$(podman run --rm ${CADDY_IMAGE} caddy hash-password --plaintext ${EXTERNAL_PASSWORD})

# Write the hashed password to the consul KV
consul kv put ${SERVICE}/config/basicauth_users/${EXTERNAL_USER} ${HASHED_PASSWORD}

echo -e "\nCaddy config is done."
