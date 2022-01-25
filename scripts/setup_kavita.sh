#!/usr/bin/env bash

SERVICE="kavita"
HOSTNAME=$(hostname)

read -e -p "Enter the externally accessible hostname for Kavita (Default: ${HOSTNAME}: " EH
ACME_HOST="${EH:-$HOSTNAME}"

echo "${KAVITA_HOST}"

consul kv put ${SERVICE}/config/kavita_host ${KAVITA_HOST}

echo -e "\nKavita config is done."
