#!/usr/bin/env bash

source variables.sh

APPLY=false

while getopts "y" opt; do
  case $opt in
    f )
      APPLY=true
      ;;
  esac
done

RCLONERPM=rclone-current-linux-amd64.rpm
RCLONESITE=https://downloads.rclone.org

echo "Runing wget -O $TMPDIR/$RCLONERPM $RCLONESITE/$RCLONERPM"
wget -O $TMPDIR/$RCLONERPM $RCLONESITE/$RCLONERPM

CURRENTVER=$(rpm -q --queryformat '%{VERSION}\n' rclone)
DOWNLOADVER=$(rpm -qp --queryformat '%{VERSION}\n' $TMPDIR/$RCLONERPM)

echo "Installed version: $CURRENTVER"
echo "Downloaded version: $DOWNLOADVER"

if [ $CURRENTVER != $DOWNLOADVER ]; then
  if [ $APPLY != true ]; then
    echo "Do you wish to update rclone?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) APPLY=true; break;;
        No ) exit 1;;
      esac
    done
  fi

	sudo yum install -y $TMPDIR/$RCLONERPM
	sudo systemctl restart rclone-media-drive
	sudo systemctl restart rclone-backup-drive
	sudo systemctl restart rclone-web
fi

#Clean up after ourselves
rm $TMPDIR/$RCLONERPM

echo "Exiting"
