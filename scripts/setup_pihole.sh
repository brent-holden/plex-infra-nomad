#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up PiHole ###\n\n"

# Create pihole config directories
mkdir -p /opt/pihole/etc
mkdir -p /opt/pihole/dnsmasq.d

# Copy over DNSmasq configs
cp ${BASH_SOURCE%/*}/../config/pihole/* /opt/pihole/dnsmasq.d

# Copy over systemd config
cp ${BASH_SOURCE%/*}/../systemd/pihole.service /usr/lib/systemd/system

# Force systemd reload
systemctl daemon-reload

# Enable systemd
echo "Enabling and starting PiHole"
systemctl enable --now pihole

echo "Done setting up PiHole"
