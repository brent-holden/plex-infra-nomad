#!/usr/bin/env bash

SERVICE="traefik"
CADDY_IMAGE="docker.io/library/traefik:latest"
HOSTNAME=$(hostname)

echo -e "\nIf you want to access Traefik externally, you'll need to forward ports 80/443 to your Traefik host.\n"
read -e -p "Enter the externally accessible hostname for Traefik (Default: ${HOSTNAME}: " EH
ACME_HOST="${EH:-$HOSTNAME}"

echo "${ACME_HOST}"

while [[ -z "${ACME_EMAIL}" ]]; do
  read -s -e -p "Enter the e-mail used for the ACME HTTP Challenge: " ACME_EMAIL
done

consul kv put ${SERVICE}/config/acme_host ${ACME_HOST}
consul kv put ${SERVICE}/config/acme_email ${ACME_EMAIL}

echo -e "\nTraefik config is done."
