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
  SRCDIR=${BACKUPS[${SERVICE}]}
  DESTDIR=${RCLONE_BACKUP_DIR}/${SERVICE}

  # Change into service backups directory
  cd ${SRCDIR}

  MATCHING=`ls *.zip 2>/dev/null | wc -l`
  if [ ${MATCHING} -eq "0" ]; then
    # Create the backup file
    echo "Backing up ${SRCDIR} to ${TMP_DIR}/${FILENAME}"
    sudo tar -cpzf ${TMP_DIR}/${FILENAME} . 2>/dev/null

    # Move it to the right place
    echo "Moving ${FILENAME} to ${DESTDIR}"
    sudo mv ${TMP_DIR}/${FILENAME} ${DESTDIR}
  else
    echo "Found zip file backups in ${SRCDIR}. No need to create backups"
    echo "Copying them over to ${DESTDIR}"
    sudo cp *.zip ${DESTDIR}
  fi
done

cd ${CWD}
