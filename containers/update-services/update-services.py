#!/usr/bin/env python

import consul
import yaml
import requests
import sys

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


services = levant['app']

for service in services:
    index, values = consul_handler.kv.get("%s/config/auto_update" % service)

    if values['Value'].decode('utf8') == 'True' and service != 'plex':
        try:
            digest_url = levant['app'][service]['container']['check_digest_url']
            output = requests.get(digest_url).json()

            images = output['images']
            for image in images:
                if image['architecture'] == services[service]['container']['architecture']:
                    print("Putting digest " + image['digest'] + " on key " + "%s/config/image_digest" % service)
                    consul_handler.kv.put("%s/config/image_digest" % service, image['digest'])

        except IndexError:
                print("No value for auto_update for %s" % service)

    else:
        print("Skipped updating %s" % service)
try:
    index, values = consul_handler.kv.get("plex/config/auto_update")
    if values['Value'].decode('utf8') == 'True':

        plex_digest_url = levant['app']['plex']['container']['check_digest_url']
        plex_output = requests.get(plex_digest_url).json()
        version = plex_output['computer']['Linux']['version']
        print("Putting version " + version + " on key " + "plex/config/version")
        consul_handler.kv.put("plex/config/version", version)
    else:
        print("auto_update has been disabled for Plex")

except:
    print("Failed to update Plex KV")
