#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# Test to make sure rclone is mounted or exit
if $(mountpoint -q "${RCLONE_BACKUP_DIR}"); then
    echo "${RCLONE_BACKUP_DIR} is mounted. Let's do this"
else
    echo "${RCLONE_BACKUP_DIR} is not mounted. Exiting"
    exit 1
fi

CWD=$(pwd)

# Loop over services defined
for SERVICE in "${!SERVICES[@]}"; do

  # Define variables per service
  FILENAME=backup_${DATE}.tar.gz
  LATEST=backup_latest.tar.gz
  SRC_DIR=${BACKUPS[${SERVICE}]}
  DEST_DIR=${RCLONE_BACKUP_DIR}/${SERVICE}

  # Change into service backups directory
  cd ${SRC_DIR}

  MATCHING=`ls *.zip 2>/dev/null | wc -l`
  if [ ${MATCHING} -eq "0" ]; then
    # Create the backup file
    echo "Backing up ${SRC_DIR} to ${TMP_DIR}/${FILENAME}"
    tar -cpzf ${TMP_DIR}/${FILENAME} . 2>/dev/null

    # Move it to the right place
    echo "Moving ${FILENAME} to ${DEST_DIR}"
    mv ${TMP_DIR}/${FILENAME} ${DEST_DIR}
  else
    echo "Found zip file backups in ${SRC_DIR}. No need to create backups"
    echo "Copying them over to ${DEST_DIR}"
    cp *.zip ${DEST_DIR}
  fi
done

cd ${CWD}
