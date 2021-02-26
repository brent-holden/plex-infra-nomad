#!/usr/bin/env bash

source variables.sh

echo -e "\n\n### Setting up rClone ###\n\n"

echo "!! You'll need a working rclone configuration to proceed !!"
echo -e "You can follow the documentation posted at http://rclone.org\n\n"


read -p "Point me to rclone.conf (default value: /root/.config/rclone/rclone.conf): " RCLONECONF
RCLONECONF=${RCLONECONF:-/root/.config/rclone/rclone.conf}

if [ ! -f "${RCLONECONF}" ]; then
  echo "File not found. Exiting"
  exit 1
fi

echo "Making service directories"
mkdir -p ${DOWNLOADS_DIR}
mkdir -p ${RCLONE_MEDIA_DIR}
mkdir -p ${RCLONE_BACKUP_DIR}
mkdir -p ${RCLONE_CONFIG_DIR}

cp ${RCLONECONF} ${RCLONE_CONFIG_DIR}

echo "Installing rclone"
yum install -y https://downloads.rclone.org/rclone-current-linux-amd64.rpm

echo "Copying service files over"
cp ${SYSTEMD_SVCFILES_DIR}/rclone* ${SYSTEMD_DIR}
systemctl daemon-reload

echo "Enabling and starting rclone services"
systemctl enable --now rclone-media-drive
systemctl enable --now rclone-backup-drive

echo "rClone Installed!"
