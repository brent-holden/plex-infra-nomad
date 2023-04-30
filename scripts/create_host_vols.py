#!/usr/bin/env python3

import yaml
import sys
import os


if len(sys.argv) < 2:
    print("Usage: python3 program.py <config_file> <node_tag>")
    sys.exit(1)

config_file = sys.argv[1]
node_tag = sys.argv[2]

try:
    with open(config_file, "r") as file:
        levant = yaml.safe_load(file)
except FileNotFoundError:
    print("Couldn't find levant.yml. Exiting.", file=sys.stderr)
    sys.exit(1)

uid = levant['common']['env']['puid']
gid = levant['common']['env']['pgid']

for service in levant['app']:
    if levant['app'][service]['tags'] == node_tag:
        try:
          for volume in levant['app'][service]['volumes']:
              directory_to_create = levant['app'][service]['volumes'][volume]['dir']

              if not os.path.exists(directory_to_create):
                  print("Created %s" % directory_to_create)
                  os.makedirs(directory_to_create, exist_ok=True)
              else:
                  print("Directory %s already exists" % directory_to_create)

              os.chown(directory_to_create, uid, gid)

        except KeyError:
            print("Got a KeyError. Volume unconfigured for service: %s" % service)

if node_tag == 'download':
    directories = [levant['common']['volumes']['downloads']['dir'], levant['common']['volumes']['downloads-complete']['dir']]

    for directory_to_create in directories:
        if not os.path.exists(directory_to_create):
            print("Created %s" % directory_to_create)
            os.makedirs(directory_to_create, exist_ok=True)
        else:
            print("Directory %s already exists" % directory_to_create)

sys.exit(0)
