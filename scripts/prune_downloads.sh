#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# Remove all downloads over 7 days
find ${DOWNLOADS_DIR} -type f -mtime +7 -exec rm {} \;

