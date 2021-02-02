#!/usr/bin/env bash

#SERVICES=(lidarr sonarr radarr tautulli hydra2 sabnzbd ombi caddy plex)

declare -A SERVICES=( [lidarr]=docker.io/linuxserver/lidarr:latest
                      [sonarr]=docker.io/linuxserver/sonarr:preview
                      [radarr]=docker.io/linuxserver/radarr:latest
                      [tautulli]=docker.io/linuxserver/tautulli:latest
                      [hydra2]=docker.io/linuxserver/nzbhydra2:latest
                      [sabnzbd]=docker.io/linuxserver/sabnzbd:latest
                      [ombi]=docker.io/linuxserver/ombi:v4-preview
                      [caddy]=docker.io/library/caddy:alpine
                      [plex]=docker.io/plexinc/pms-docker:plexpass
                    )
declare -A BACKUPS=(  [lidarr]=/opt/lidarr/Backups/scheduled
                      [sonarr]=/opt/sonarr/Backups/scheduled
                      [radarr]=/opt/radarr/Backups/scheduled
                      [tautulli]=/opt/tautulli/backups
                      [hydra2]=/opt/hydra2/backup
                      [sabnzbd]=/opt/sabnzbd/
                      [ombi]=/opt/ombi/
                      [caddy]=/opt/caddy/
                      [plex]=/opt/plex/Backups
                    )
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
PLEX_TOKEN="X-Plex-Token: Qq9YyApAKHyzkptsS2_g"
NOMAD_PLUGIN_DIR=/opt/nomad/plugins
