#!/usr/bin/env bash

function setup_infra_host() {
  source ${BASH_SOURCE%/*}/prep_network_host.sh
  source ${BASH_SOURCE%/*}/setup_containerd.sh
  source ${BASH_SOURCE%/*}/setup_consul_server.sh
  source ${BASH_SOURCE%/*}/setup_nomad_server.sh
}

function setup_media_host() {
  source ${BASH_SOURCE%/*}/prep_media_host.sh
  source ${BASH_SOURCE%/*}/setup_consul_agent.sh
  source ${BASH_SOURCE%/*}/setup_consul_template.sh
  source ${BASH_SOURCE%/*}/setup_nomad_client.sh
  source ${BASH_SOURCE%/*}/setup_rclone.sh
  source ${BASH_SOURCE%/*}/setup_containerd.sh
  source ${BASH_SOURCE%/*}/setup_caddy.sh
  source ${BASH_SOURCE%/*}/setup_services.sh
  source ${BASH_SOURCE%/*}/setup_backup.sh
  source ${BASH_SOURCE%/*}/update_containers_consul_notify.sh
  source ${BASH_SOURCE%/*}/update_plex_consul_notify.sh
}

function usage() {

echo "
Usage: setup.sh [options]

  This setup script will install and configure all of the necessary components
  needed to operate Plex and its associated services. This will need root access
  to modify the parts of the OS necessary, so run either as root or with sudo.

Options:

  -i=<host_type>
      Sets the host type that you want to install. Useful for automation scripts.

      host_type can be one of two options:

        * media
        * infra


  -h
      Prints this useful help dialog

Example:

  setup.sh -i infra
" >&2
}

while getopts hi: FLAG
do
  case "${FLAG}" in
    i)
      CHOICE=${OPTARG};;
    h)
      usage
      exit 0;;
  esac
done

if [ -z "$CHOICE" ]; then
  CHOICE=$(whiptail --title "Installation" --menu "Which host do you want to do? Setup the infra host first" 20 118 10 \
    "infra" "Select this to bootstrap the host used for hosting infrastructure (Nomad and Consul servers)" \
    "media" "Select this to bootstrap the host used for running media services" \
    3>&2 2>&1 1>&3)
fi

case "$CHOICE" in
  "infra")
    echo "Setting up the infrastructure host"
    setup_infra_host
    ;;
  "media")
    echo "Setting up the media host"
    setup_media_host
    ;;
  *)
    echo "Setup mode cancelled. Supported modes are 'infra' or 'media'" >&2
    exit 0
    ;;
esac


