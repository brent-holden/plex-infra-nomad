#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Setting up Backups ###\n\n"

# Test to make sure we're mounted or exit
if $(mountpoint -q "$RCLONEBACKUPDIR"); then
    echo "$RCLONEBACKUPDIR is mounted. Let's do this!"
else
    echo "$RCLONEBACKUPDIR is not a mounted. Exiting"
    exit 1
fi

# Loop over services defined
for SERVICE in "${!SERVICES[@]}"; do

  BACKUPDIR=$RCLONEBACKUPDIR/$SERVICE

  if [ -d "$BACKUPDIR" ]; then
    # Create backup directory
    echo "Directory $BACKUPDIR not found. Creating."
    sudo mkdir -p $BACKUPDIR
  fi

  # Change directory permissions
  echo "Changing $BACKUPDIR permissions to: $PLEXUSER.$PLEXGROUP"
  sudo chown -R $PLEXUSER.$PLEXGROUP $BACKUPDIR

done

# Get current directory of the repo
#REPODIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

# Setup cronjob
#echo "Copying backup configuration to /etc/cron.d"
#sudo cp ${BASH_SOURCE%/*}/../cron/backup-plex ${CRONDIR}
#sudo sed -i "s~%%SCRIPT_REPO%%~${REPODIR}~" ${CRONDIR}/backup-plex
#sudo systemctl restart crond

#echo "Done setting up backups"
