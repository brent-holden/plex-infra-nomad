#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Preparing your system ###\n\n"

# Add the plex user and group with specified UID before doing anything
echo "Adding ${PLEX_USER} with UID:${PLEX_UID}"
adduser ${PLEX_USER} --uid=${PLEX_UID} -U

# Install packages needed
echo "Installing packages: ${PACKAGES}"
yum -y install ${PACKAGES}

# Enable cockpit
echo "Enabling cockpiti for remote web administration. Access via https://<ip>:9090"
systemctl enable --now cockpit.socket

echo "Disabling FirewallD for containerd"
systemctl disable --now firewalld

# Disable SELinux because reasons. Sorry Dan
echo "Disabling SELinux. This will require a reboot to take effect"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux

# Create download directories
for MEDIATYPE in "${DOWNLOADABLES[@]}"; do

  MEDIADIR=${COMPLETED_DIR}/${MEDIATYPE}

  echo "Creating ${MEDIADIR}"
  mkdir -p ${MEDIADIR}

  echo "Changing permissions on ${MEDIADIR} to ${PLEX_USER}.${PLEX_GROUP}"
  chown -R ${PLEX_USER}.${PLEX_GROUP} ${MEDIADIR}

done

echo "Creating ${TRANSCODE_DIR}"
mkdir -p ${TRANSCODE_DIR}

echo "Changing permissions on ${TRANSCODE_DIR} to ${PLEX_USER}.${PLEX_GROUP}"
chown -R ${PLEX_USER}.${PLEX_GROUP} ${TRANSCODE_DIR}

echo "Done preparing your system. Ready for services installation"
