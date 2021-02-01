#!/usr/bin/env bash

source variables.sh

echo -e "\n\n### Setting up rClone ###\n\n"

echo "!! You'll need a working rclone configuration to proceed !!"
echo -e "You can follow the documentation posted at http://rclone.org\n\n" 


read -p "Point me to rclone.conf (default value: /root/.config/rclone/rclone.conf): " RCLONECONF
RCLONECONF=${RCLONECONF:-/root/.config/rclone/rclone.conf}

if [ ! -f "$RCLONECONF" ]; then
  echo "File not found. Exiting"
  exit 1
fi

echo "Making service directories"
sudo mkdir -p $DOWNLOADSDIR
sudo mkdir -p $RCLONEMEDIADIR
sudo mkdir -p $RCLONEBACKUPDIR
sudo mkdir -p $RCLONECONFIGDIR

sudo cp $RCLONECONF $RCLONECONFIGDIR

echo "Installing rclone"
sudo yum install -y https://downloads.rclone.org/rclone-current-linux-amd64.rpm

echo "Copying service files over"
sudo cp $SYSTEMDSVCFILESDIR/rclone* $SYSTEMDDIR
sudo systemctl daemon-reload

echo "Enabling and starting rclone services"
sudo systemctl enable --now rclone-media-drive
sudo systemctl enable --now rclone-backup-drive
sudo systemctl enable --now rclone-web

echo "rClone Installed!"
