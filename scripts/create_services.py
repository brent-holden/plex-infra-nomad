#!/usr/bin/env python3

import consul
import yaml
import requests
import sys
import os


try:
    with open("../levant.yml", "r") as file:
        levant = yaml.safe_load(file)
except FileNotFoundError:
    print("Couldn't find levant.yml. Exiting.", file=sys.stderr)
    sys.exit(1)

try:
    consul_handler = consul.Consul()
except:
    print("Couldn't open connection to Consul. Exiting", file=sys.stderr)
    sys.exit(1)

print("Creating levant config KV for update-services routine")
consul_handler.kv.put('update-services/config/levant.yml', yaml.safe_dump(levant))

print("Time to make the donuts")
for service in levant['app']:
    print("Found service config: " + service)
    for item in levant['app'][service]['container']:
        print("Writing to Consul KV %s/config/%s: %s" % (service,item,levant['app'][service]['container'][item]))
        consul_handler.kv.put("%s/config/%s" % (service, item), str(levant['app'][service]['container'][item]))


#    index, values = consul_handler.kv.get("%s/config/auto_update" % service)
#
#    try:
#        digest_url = levant['app'][service]['container']['check_digest_url']
#        output = requests.get(digest_url).json()
#
#        if values['Value'].decode('utf8') == 'true':
#            print("Putting digest " + output['digest'] + " on key " + "%s/config/image_digest" % service)
#            consul_handler.kv.put("%s/config/image_digest" % service, output['digest'])
#        else:
#            print("Skipped %s because auto_update was set to false" % service)
#
#    except TypeError:
#            print("No value for auto_update for %s" % service)
#
#    except:
#        print("Something broke trying to get the JSON data from the URL. BUSTED!")
