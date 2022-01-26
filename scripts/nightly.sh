#!/usr/bin/env bash

# Pull new containers and update Consul key
source ${BASH_SOURCE%/*}/update_containers_consul_notify.sh

# Update Consul key with Plexpass version
source ${BASH_SOURCE%/*}/update_plex_consul_notify.sh

# Remove stale downloads
source ${BASH_SOURCE%/*}/prune_downloads.sh

# Remove stale containers
source ${BASH_SOURCE%/*}/clean_docker.sh
