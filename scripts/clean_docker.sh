#!/usr/bin/env bash

echo "Pruning containers"
docker image prune -f
