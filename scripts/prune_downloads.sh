#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# Remove all downloads over 7 days
sudo find ${DOWNLOADS_DIR} -type f -mtime +7 -exec rm {} \;

