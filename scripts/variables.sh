#!/usr/bin/env bash

declare -A SERVICES=( [lidarr]=ghcr.io/linuxserver/lidarr:latest,auto_update
                      [sonarr]=ghcr.io/linuxserver/sonarr:preview,auto_update
                      [radarr]=ghcr.io/linuxserver/radarr:latest,auto_update
                      [tautulli]=ghcr.io/linuxserver/tautulli:latest,auto_update
                      [hydra2]=ghcr.io/linuxserver/nzbhydra2:latest,auto_update
                      [sabnzbd]=ghcr.io/linuxserver/sabnzbd:latest,auto_update
                      [ombi]=ghcr.io/linuxserver/ombi:development,auto_update
                      [caddy]=ghcr.io/library/caddy:alpine,auto_update
                      [traefik]=ghcr.io/library/traefik:latest,auto_update
                      [plex]=ghcr.io/plexinc/pms-docker:plexpass,auto_update
                    )
declare -A BACKUPS=(  [lidarr]=/opt/lidarr/Backups/scheduled
                      [sonarr]=/opt/sonarr/Backups/scheduled
                      [radarr]=/opt/radarr/Backups/scheduled
                      [tautulli]=/opt/tautulli/backups
                      [hydra2]=/opt/hydra2/backup
                      [sabnzbd]=/opt/sabnzbd/
                      [ombi]=/opt/ombi/
                      [caddy]=/opt/caddy/
                      [traefik]=/opt/traefik/config/
                      [plex]=/opt/plex/Backups
                    )
DOWNLOADABLES=(movies tv music other)
DATE=`date +%d-%m-%Y`
CRON_DIR=/etc/cron.d
OPT_DIR=/opt
TMP_DIR=/tmp
JOBS_DIR=../jobs
CONSUL_TEMPLATE_CONF_DIR=/etc/consul-template.d
RCLONE_RPM=rclone-current-linux-amd64.rpm
RCLONE_URL=https://downloads.rclone.org
RCLONE_DIR=/mnt/rclone
RCLONE_MEDIA_DIR=${RCLONE_DIR}/media
RCLONE_MEDIA_CACHE_DIR=${RCLONE_CACHE_DIR}/media
RCLONE_CACHE_DIR=${RCLONE_DIR}/cache
RCLONE_BACKUP_DIR=${RCLONE_DIR}/backup
RCLONE_BACKUP_CACHE_DIR=${RCLONE_CACHE_DIR}/backup
RCLONE_CONFIG_DIR=${OPT_DIR}/rclone
RCLONE_CONF_TEMPLATE=../config/rclone/rclone.conf.tpl
RCLONE_CT_CONF=../config/rclone/rclone.hcl
DOWNLOADS_DIR=/mnt/downloads
COMPLETED_DIR=${DOWNLOADS_DIR}/complete
TRANSCODE_DIR=/mnt/transcode
SYSTEMD_SVCFILES_DIR=../systemd
SYSTEMD_DIR=/usr/lib/systemd/system
PLEX_USER=plex
PLEX_GROUP=plex
PLEX_UID=1100
PACKAGES="fuse rsync vim git podman"
NOMAD_PLUGIN_DIR=/opt/nomad/plugins
