#!/usr/bin/env bash

shopt -s extglob
source variables.sh

echo -e "\n\n### Setting up rClone ###\n\n"

echo "!! You'll need a working rclone configuration to proceed !!"
echo -e "You can follow the documentation posted at http://rclone.org\n\n"


read -p "Point me to rclone.conf (default value: /root/.config/rclone/rclone.conf): " RCLONE_CONF
RCLONE_CONF=${RCLONE_CONF:-/root/.config/rclone/rclone.conf}

if [ ! -f "${RCLONE_CONF}" ]; then
  echo "File not found. Exiting"
  exit 1
fi

echo "Setting up Consul to store the configuration values from rclone.conf"
while IFS='= ' read KEY VALUE
do
  if [[ ! ${KEY} =~ ^\[.*  && ! -z ${KEY} ]]; then
    echo "${KEY} ==== ${VALUE}"
    consul kv put rclone/config/${KEY} ${VALUE}
  fi
done < "${RCLONE_CONF}"

echo "Making service directories"
mkdir -p ${DOWNLOADS_DIR}
mkdir -p ${RCLONE_MEDIA_DIR}
mkdir -p ${RCLONE_BACKUP_DIR}
mkdir -p ${RCLONE_CONFIG_DIR}
mkdir -p ${RCLONE_MEDIA_CACHE_DIR}
mkdir -p ${RCLONE_BACKUP_CACHE_DIR}


echo "Copying the rclone.conf template to the config directory"
cp ${RCLONE_CONF_TEMPLATE} ${RCLONE_CONFIG_DIR}

echo "Setting up consul-template to load the rclone.conf template.\nWe're relying on consul-template service being active and enabled"
cp ${RCLONE_CT_CONF} ${CONSUL_TEMPLATE_CONF_DIR}

echo "Installing rclone"
yum install -y ${RCLONE_URL}/${RCLONE_RPM}

echo "Copying service files over"
cp ${SYSTEMD_SVCFILES_DIR}/rclone* ${SYSTEMD_DIR}
systemctl daemon-reload

echo "Enabling and starting rclone services"
systemctl enable --now rclone-media-drive
systemctl enable --now rclone-backup-drive

echo "rClone Installed!"
