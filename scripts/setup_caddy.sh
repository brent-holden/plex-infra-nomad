#!/usr/bin/env bash

SERVICE="caddy"
CADDY_IMAGE="docker.io/library/caddy:alpine"
HOSTNAME=$(hostname)

echo -e "\nIf you want to access Caddy externally, you'll need to forward ports 80/443 to your Caddy host.\n"
read -e -p "Enter the externally accessible hostname for Caddy (Default: ${HOSTNAME}: " EH
EXTERNAL_HOST="${EH:-$HOSTNAME}"

echo "${EXTERNAL_HOST}"

echo -e "\nLet's protect your /downloads directory from uninvited guests."

while [[ -z "${EXTERNAL_USER}" ]]; do
  read -e -p "Enter the a user name for basic auth: " EXTERNAL_USER
done

while [[ -z "${EXTERNAL_PASSWORD}" ]]; do
  read -s -e -p "Enter the password for that user: " EXTERNAL_PASSWORD
done

echo -e "\n\nPulling caddy container to generate our bcrypt password"
HASHED_PASSWORD=$(podman run --rm ${CADDY_IMAGE} caddy hash-password --plaintext ${EXTERNAL_PASSWORD} && podman rmi ${CADDY_IMAGE})
echo "Hashed password has been generated"

consul kv put ${SERVICE}/config/external_hostname ${EXTERNAL_HOST}
consul kv put ${SERVICE}/config/basicauth_users/${EXTERNAL_USER} ${HASHED_PASSWORD}

echo -e "\nCaddy config is done."
