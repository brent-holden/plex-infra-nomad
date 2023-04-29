#!/usr/bin/env python3

import consul
import yaml
import requests
import sys
import os

if len(sys.argv) < 3:
    print("Usage: python3 program.py -f <levant_file> -c <consul_server>")
    sys.exit(1)

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--config_file", help="path to configuration file")
parser.add_argument("-c", "--consul_host", help="Consul host name or IP address")
args = parser.parse_args()

config_file = args.config_file
consul_host = args.consul_host

try:
    with open(config_file, "r") as file:
        levant = yaml.safe_load(file)
except FileNotFoundError:
    print("Couldn't find levant.yml. Exiting.", file=sys.stderr)
    sys.exit(1)

try:
    consul_handler = consul.Consul(host=consul_host)
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

print("All done.")
