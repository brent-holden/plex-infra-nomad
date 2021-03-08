#!/usr/bin/env bash
shopt -s extglob

source ${BASH_SOURCE%/*}/variables.sh

function setup_rclone_config() {

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

}

function setup_consultemplate() {

  echo "Copying the rclone.conf template to the config directory"
  cp ${RCLONE_CONF_TEMPLATE} ${RCLONE_CONFIG_DIR}

  echo -e "Setting up consul-template to load the rclone.conf template.\nWe're relying on consul-template service being active and enabled"
  cp ${RCLONE_CT_CONF} ${CONSUL_TEMPLATE_CONF_DIR}

  echo "Restarting consul-template for config"
  systemctl restart consul-template

}

function setup_media_drive() {

  mkdir -p ${DOWNLOADS_DIR}
  mkdir -p ${RCLONE_MEDIA_DIR}
  mkdir -p ${RCLONE_MEDIA_CACHE_DIR}

  echo "Copying service files over"
  cp ${SYSTEMD_SVCFILES_DIR}/rclone-media-drive.service ${SYSTEMD_DIR}
  systemctl daemon-reload

  echo "Enabling and starting rclone services"
  systemctl enable --now rclone-media-drive

}

function setup_backup_drive() {

  echo "Making service directories"
  mkdir -p ${RCLONE_BACKUP_DIR}
  mkdir -p ${RCLONE_BACKUP_CACHE_DIR}

  echo "Copying rclone-backup-drive service unit"
  cp ${SYSTEMD_SVCFILES_DIR}/rclone-backup-drive.service ${SYSTEMD_DIR}
  systemctl daemon-reload

  echo "Enabling and starting rclone services"
  systemctl enable --now rclone-backup-drive

}

function install_rclone() {

  echo "Installing rclone"
  yum install -y ${RCLONE_URL}/${RCLONE_RPM}

}


SHORT=sb
LONG=skipconfig,backuponly
SKIPCONFIG=false
BACKUPONLY=false

echo -e "\n### Setting up rClone ###\n\n"

echo "!! You'll need a working rclone configuration to proceed !!"
echo -e "You can follow the documentation posted at http://rclone.org\n\n"

OPTS=$(getopt --options ${SHORT} --long ${LONG})

while true ; do
  case "$1" in
    -s | --skipconfig )
      SKIPCONFIG=true
      shift
      ;;
    -b | --backuponly )
      BACKUPONLY=true
      shift
      ;;
    * ) break ;;
  esac
done


if [[ ${SKIPCONFIG} = false ]]; then
  setup_rclone_config
fi

echo "Creating configuration directory"
mkdir -p ${RCLONE_CONFIG_DIR}

install_rclone
setup_consultemplate
setup_backup_drive

if [[ ${BACKUPONLY} = false ]]; then
  setup_media_drive
fi

echo "rClone Installed!"
