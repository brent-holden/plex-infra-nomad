#!/usr/bin/env bash

DOWNLOADABLES=(movies tv music other)
DATE=`date +%d-%m-%Y`
CRON_DIR=/etc/cron.d
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
OPT_DIR=/opt

declare -A SERVICES=( [caddy]=docker.io/library/caddy:alpine,auto_update
                      [kavita]=docker.io/kizaing/kavita:latest:latest,auto_update
                      [lidarr]=lscr.io/linuxserver/lidarr:latest,auto_update
                      [ombi]=lscr.io/linuxserver/ombi:latest,auto_update
                      [overseerr]=lscr.io/linuxserver/overseerr:latest,auto_update
                      [plex]=docker.io/plexinc/pms-docker:plexpass,auto_update
                      [prowlarr]=lscr.io/linuxserver/prowlarr:nightly,auto_update
                      [radarr]=lscr.io/linuxserver/radarr:latest,auto_update
                      [readarr]=lscr.io/linuxserver/readarr:nightly,auto_update
                      [sabnzbd]=lscr.io/linuxserver/sabnzbd:latest,auto_update
                      [sonarr]=lscr.io/linuxserver/sonarr:latest,auto_update
                      [tautulli]=lscr.io/linuxserver/tautulli:latest,auto_update
                      [traefik]=docker.io/library/traefik:latest,auto_update
                      [netbootxyz]=docker.io/linuxserver/netbootxyz:latest,auto_update
                      [prometheus]=docker.io/prom/prometheus:latest,auto_update
                      [librespeed]=lscr.io/linuxserver/librespeed:latest,auto_update
                      [tfc-agent]=docker.io/hashicorp/tfc-agent:latest,auto_update
                    )

declare -A BACKUPS=(  [caddy]=${OPT_DIR}/caddy/
                      [kavita]=${OPT_DIR}/kavita/
                      [lidarr]=${OPT_DIR}/lidarr/Backups/scheduled
                      [ombi]=${OPT_DIR}/ombi/
                      [plex]=${OPT_DIR}/plex/Backups
                      [prowlarr]=${OPT_DIR}/prowlarr/Backups/scheduled
                      [radarr]=${OPT_DIR}/radarr/Backups/scheduled
                      [readarr]=${OPT_DIR}/readarr/Backups/scheduled
                      [sabnzbd]=${OPT_DIR}/sabnzbd/
                      [sonarr]=${OPT_DIR}/sonarr/Backups/scheduled
                      [tautulli]=${OPT_DIR}/tautulli/backups
                      [traefik]=${OPT_DIR}/traefik/config/
                      [netbootxyz]=/opt/netbootxyz
                      [prometheus]=/dev/null
                      [librespeed]=/dev/null
                      [tfc-agent]=/dev/null
                    )
