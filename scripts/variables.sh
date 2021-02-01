#!/usr/bin/env bash

SERVICES=(lidarr sonarr radarr tautulli hydra2 sabnzbd ombi nginx plex)
DOWNLOADABLES=(movies tv music other)
DATE=`date +%d-%m-%Y`
CRONDIR=/etc/cron.d
OPTDIR=/opt
TMPDIR=/tmp
RCLONEDIR=/mnt/rclone
RCLONEMEDIADIR=$RCLONEDIR/media
RCLONECACHEDIR=$RCLONEDIR/cache-db
RCLONEBACKUPDIR=$RCLONEDIR/backup
RCLONECONFIGDIR=$OPTDIR/rclone
DOWNLOADSDIR=/mnt/downloads
COMPLETEDDIR=$DOWNLOADSDIR/complete
TRANSCODEDIR=/mnt/transcode
SYSTEMDSVCFILESDIR=../systemd
SYSTEMDDIR=/usr/lib/systemd/system
PLEXUSER=plex
PLEXGROUP=plex
PLEXUID=1100
PACKAGES="fuse rsync vim podman podman-docker podman-remote cockpit cockpit-podman"
