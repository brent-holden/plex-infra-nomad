#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo "Let's start some services"
cd ${BASH_SOURCE%/*}/${JOBS_DIR}
for i in *; do nomad run $i; done

