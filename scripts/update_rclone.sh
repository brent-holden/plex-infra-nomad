#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

function upgrade_available () {
  echo "Running wget -O ${TMP_DIR}/${RCLONE_RPM} ${RCLONE_URL}/${RCLONE_RPM}"
  wget -O ${TMP_DIR}/${RCLONE_RPM} ${RCLONE_URL}/${RCLONE_RPM}

  CURRENT_VER=$(rpm -q --queryformat '%{VERSION}\n' rclone)
  DOWNLOAD_VER=$(rpm -qp --queryformat '%{VERSION}\n' ${TMP_DIR}/${RCLONE_RPM})

  rm ${TMP_DIR}/${RCLONE_RPM}

  echo "Installed version:" ${CURRENT_VER}
  echo "Downloaded version:" ${DOWNLOAD_VER}
  echo "-----------"

  [[ ${CURRENT_VER} != ${DOWNLOAD_VER} ]]
    return
}

function update_rclone () {
  yum install -y ${TMP_DIR}/${RCLONE_RPM}
  systemctl restart rclone-media-drive
  systemctl restart rclone-backup-drive
}


if upgrade_available; then
  echo "Update to rclone available. Updating.."
  update_rclone
else
  echo "No update available"
fi

echo "Exiting."
