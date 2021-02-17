#!/usr/bin/env bash

source variables.sh

APPLY=false

while getopts "y" OPT; do
  case ${OPT} in
    f )
      APPLY=true
      ;;
  esac
done

RCLONERPM=rclone-current-linux-amd64.rpm
RCLONESITE=https://downloads.rclone.org

echo "Runing wget -O ${TMP_DIR}/${RCLONERPM} ${RCLONESITE}/${RCLONERPM}"
wget -O ${TMP_DIR}/${RCLONERPM} ${RCLONESITE}/${RCLONERPM}

CURRENTVER=$(rpm -q --queryformat '%{VERSION}\n' rclone)
DOWNLOADVER=$(rpm -qp --queryformat '%{VERSION}\n' ${TMP_DIR}/${RCLONERPM})

echo "Installed version: ${CURRENTVER}"
echo "Downloaded version: ${DOWNLOADVER}"

if [ ${CURRENTVER} != ${DOWNLOADVER} ]; then
  if [ ${APPLY} != true ]; then
    echo "Do you wish to update rclone?"
    select yn in "Yes" "No"; do
      case ${yn} in
        Yes ) APPLY=true; break;;
        No ) exit 1;;
      esac
    done
  fi

	sudo yum install -y ${TMP_DIR}/${RCLONERPM}
	sudo systemctl restart rclone-media-drive
	sudo systemctl restart rclone-backup-drive
	#sudo systemctl restart rclone-web
fi

#Clean up after ourselves
rm ${TMP_DIR}/${RCLONERPM}

echo "Exiting"
