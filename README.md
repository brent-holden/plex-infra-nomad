# Running Plex and media services on Nomad
This is a collection of nomad job files, scripts, crontabs, and systemd configurations I used to setup Plex and associated services which has been tested on CentOS 8 Stream. It should work fine on CentOS 9 Streami once they release docker-ce for the OS.

You'll need the following before you get started:

* A Plex claim token, available at https://plex.tv/claim
* A DNS server setup on your network to resolve custom hostnames. I use unbound on my infrastructure server, YMMV. DNSMasq would work just fine. You'll need it to forward requests for your service instances to Consul for resolution. Setting it up is beyond the scope of this guide.
* A DNS hostname for your server. I defined mine externally so that the LetsEncrypt checks would work, and internally so that I wouldn't need to hairpin my service lookups. My hostname is plex-request.domain.name
* A DNS hostname for Kavita. Kavita doesn't (yet) support a reverse proxy, so it needs its own sub-domain. Mine is kavita.domain.name
* Fresh installs of CentOS 8 Stream on your nodes
* An account with access to sudo
* Some patience. This repo is imperfect and I know it has bugs in it


Clone this repository using:
```console
$ mkdir Code && cd "$_"
$ git clone https://github.com/brent-holden/plex-nomad.git
$ cd plex-nomad
```

Before running the next commands, you'll need to make sure you have a valid rclone configuration. You can find the instructions on how to do that on the [RClone Drive instructions](https://rclone.org/drive/). I've included an [example rclone configuration file](rclone/rclone.conf.example) for reference in this repository.

The setup.sh script assumes you're running with access to sudo. This script will prepare the system for installation of rclone, installing additional services and Plex. To complete the installation, you'll need three things:
* A working rclone configuration. Your rclone mount must have /Media and /Backups on it. This script will install rclone but but won't configure it for you. You'll need to follow the guide above and provide the configuration file (rclone.conf) during the install.
* A Plex claim token. You can get this from plex.tv/claim once the script asks for it during installation
* Port 80 has been forwarded to your host for ACME certbot. Certbot will fire up every night during backups but won't listen all the time.
* Google Drive needs to be setup with /Media and /Backups folders in the root directory.


```console
$ cd scripts
$ ./setup.sh
```
You'll need to decide what kind of host you're going to install. There are three kinds I've thought about:
* infra
* media
* allinone

In my home lab, I have one server I use as a cluster manager and where I install network services like pihole and beefier server where I run plex and all of my media services.

My Google drive has two directories in /, Media and Backups. The rclone-media-drive mounts /Media, and rclone-backup-drive mounts /Backups

This is the directory structure that will need to be in place before we start. The setup scripts will create all of the services-related directories for you.
```console
mnt/
├── downloads
└── rclone
    ├── backup
    ├── cache
    │   ├── backup
    │   └── media
    └── media
        ├── Books
        ├── Movies
        ├── Music
        └── TV
opt/
```


If you have backups in the appropriate folders, the restore_services script will look for backup_latest.tar.gz and untar it into the appropriate directory in /opt. If you don't have any backups, it will fail during the untar but will continue and setup all of the systemd service files for you.


Once the setup script has completed, traefik will be sitting on your host in a reverse proxy configuration. You can access your services using https://your.host.name/{radarr,sonarr,lidarr,prowlarr,readarr,sabznbd,tautulli}. Kavita will need to have its own hostname due to a lack of reverse proxy support. You can access that via https://kavita.host.name/

Going to https://your.host.name/ will forward you to Ombi

Plex will be available at http://your.host.name:32400/web or through https://plex.tv/


