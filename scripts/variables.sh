#!/usr/bin/env bash

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
CRON_DIR=/etc/cron.d
OPT_DIR=/opt
TMP_DIR=/tmp
RCLONE_DIR=/mnt/rclone
RCLONE_MEDIA_DIR=${RCLONE_DIR}/media
RCLONE_CACHE_DIR=${RCLONE_DIR}/cache-db
RCLONE_BACKUP_DIR=${RCLONE_DIR}/backup
RCLONE_CONFIG_DIR=${OPT_DIR}/rclone
DOWNLOADS_DIR=/mnt/downloads
COMPLETED_DIR=${DOWNLOADS_DIR}/complete
TRANSCODE_DIR=/mnt/transcode
SYSTEMD_SVCFILES_DIR=../systemd
SYSTEMD_DIR=/usr/lib/systemd/system
PLEX_USER=plex
PLEX_GROUP=plex
PLEX_UID=1100
PACKAGES="fuse rsync vim podman podman-docker podman-remote cockpit cockpit-podman"
PLEX_TOKEN="{{YOUR_TOKEN_HERE}}"
NOMAD_PLUGIN_DIR=/opt/nomad/plugins
