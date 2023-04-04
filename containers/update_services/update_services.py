#!/usr/bin/env python3

import consul
import yaml
import requests
import sys

services = [
            "authelia",
            "kavita",
            "lidarr",
            "netbootxyz",
            "overseerr",
            "prowlarr",
            "radarr",
            "rclone_restic",
            "readarr",
            "sabnzbd",
            "sonarr",
            "tautulli",
            "traefik",
            ]

try:
    with open('levant.yml', 'r') as file:
        levant = yaml.safe_load(file)
except FileNotFoundError:
    print("Couldn't find levant.yml. Exiting.", file=sys.stderr)
    sys.exit(1)

try:
    consul_handler = consul.Consul()
except:
    print("Couldn't open connection to Consul. Exiting", file=sys.stderr)
    sys.exit(1)

for service in services:
    index, values = consul_handler.kv.get("%s/config/auto_update" % service)

    try:
        digest_url = levant['app'][service]['container']['check_digest_url']
        output = requests.get(digest_url).json()

        if values['Value'].decode('utf8') == 'true':
            print("Putting digest " + output['digest'] + " on key " + "%s/config/image_digest" % service)
            consul_handler.kv.put("%s/config/image_digest" % service, output['digest'])
        else:
            print("Skipped %s because auto_update was set to false" % service)

    except TypeError:
            print("No value for auto_update for %s" % service)

    except:
        print("Something broke trying to get the JSON data from the URL. BUSTED!")

try:
    index, values = consul_handler.kv.get("plex/config/auto_update")
    if values['Value'].decode('utf8') == 'true':

        plex_digest_url = levant['app']['plex']['container']['check_digest_url']
        plex_output = requests.get(plex_digest_url).json()
        version = plex_output['computer']['Linux']['version']
        print("Putting version " + version + " on key " + "plex/config/version")
        consul_handler.kv.put("plex/config/version", version)
    else:
        print("auto_update has been disabled for Plex")

except:
    print("Failed to update Plex KV")
