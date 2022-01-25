#!/usr/bin/env bash

SERVICE="traefik"
HOSTNAME=$(hostname)

echo -e "\nIf you want to access Traefik externally, you'll need to forward ports 80/443 to your Traefik host.\n"
read -e -p "Enter the externally accessible hostname for Traefik (Default: ${HOSTNAME}): " EH
ACME_HOST="${EH:-$HOSTNAME}"

while [[ -z "${ACME_EMAIL}" ]]; do
  read -e -p "\nEnter the e-mail used for the ACME HTTP Challenge: " ACME_EMAIL
done

echo -e "\nIf you want the Traefik service registered to Traefik Pilot, register your instance and grab the token below.\nIf you don't have a token yet, you can find the token in the Consul KV traefik/config/pilot_token\n"
read -e -p "Enter the Pilot Connect token for Traefik (Default: TOKEN): " ET
PILOT_TOKEN="${ET:-TOKEN}"

consul kv put ${SERVICE}/config/acme_host ${ACME_HOST}
consul kv put ${SERVICE}/config/acme_email ${ACME_EMAIL}
consul kv put ${SERVICE}/config/pilot_token ${PILOT_TOKEN}

echo -e "\nTraefik config is done."
