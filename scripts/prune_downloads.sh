#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

# Remove all downloads over 7 days
find ${DOWNLOADS_DIR} -mindepth 2 -mtime +7 -exec rm -rf {} \;

