#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Removing Installed Services ###\n\n"

# Loop over services defined
for SERVICE in "${SERVICES[@]}"; do

  # Disable
  echo "Stopping ${SERVICE}"
  nomad stop -purge ${SERVICE}

done

echo "Done removing services"
