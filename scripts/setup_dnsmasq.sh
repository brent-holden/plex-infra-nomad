#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up dnsmasq ###\n\n"

# Create pihole config directories
mkdir -p /etc/dnsmasq
mkdir -p /etc/dnsmasq.d

# Copy over DNSmasq configs
cp ${BASH_SOURCE%/*}/../config/dnsmasq/dnsmasq/* /etc/dnsmasq/
cp ${BASH_SOURCE%/*}/../config/dnsmasq/dnsmasq.d/* /etc/dnsmasq.d/

# Enable dnsmasq
echo "Enabling and starting dnsmasq"
systemctl enable --now dnsmasq

echo "Done setting up dnsmasq"
