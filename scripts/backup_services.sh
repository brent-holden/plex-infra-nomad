#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# Test to make sure rclone is mounted or exit
if $(mountpoint -q "${RCLONEBACKUPDIR}"); then
    echo "${RCLONEBACKUPDIR} is mounted. Let's do this"
else
    echo "${RCLONEBACKUPDIR} is not mounted. Exiting"
    exit 1
fi

CWD=$(pwd)

# Loop over services defined
for SERVICE in "${!SERVICES[@]}"; do

  # Define variables per service
  FILENAME=backup_${DATE}.tar.gz
  LATEST=backup_latest.tar.gz
  SRCDIR=${BACKUPS[${SERVICE}]}
  DESTDIR=${RCLONEBACKUPDIR}/${SERVICE}

  # Change into service backups directory
  cd ${SRCDIR}

  MATCHING=`ls *.zip 2>/dev/null | wc -l`
  if [ ${MATCHING} -eq "0" ]; then
    # Create the backup file
    echo "Backing up ${SRCDIR} to ${TMPDIR}/${FILENAME}"
    sudo tar -cpzf ${TMPDIR}/${FILENAME} . 2>/dev/null

    # Move it to the right place
    echo "Moving ${FILENAME} to ${DESTDIR}"
    sudo mv ${TMPDIR}/${FILENAME} ${DESTDIR}
  else
    echo "Found zip file backups in ${SRCDIR}. No need to create backups"
    echo "Copying them over to ${DESTDIR}"
    sudo cp *.zip ${DESTDIR}
  fi
done

cd ${CWD}
