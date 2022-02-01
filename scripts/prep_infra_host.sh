#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Preparing your server host ###\n\n"

# Install packages needed
echo "Installing packages: ${PACKAGES}"
yum -y install ${PACKAGES}

# Enable cockpit -- disabling by default for now
#echo "Enabling cockpiti for remote web administration. Access via https://<ip>:9090"
#systemctl enable --now cockpit.socket

echo "Disabling FirewallD"
systemctl disable --now firewalld

# Disable SELinux because reasons. Sorry Dan
echo "Disabling SELinux. This will require a reboot to take effect"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux

echo "Done preparing your system. Ready for services installation"
