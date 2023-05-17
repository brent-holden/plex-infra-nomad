#!/bin/bash

docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/lidarr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/lidarr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/radarr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/radarr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/sonarr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/sonarr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/readarr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/readarr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/prowlarr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/prowlarr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/overseerr:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/overseerr restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/sabnzbd:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/sabnzbd restore latest --target /
docker run --rm -e RESTIC_PASSWORD=$RESTIC_PASSWORD -v /opt/services/kavita:/config restic/restic --repo rest:http://restic-endpoint.service.consul:7070/kavita restore latest --target /
