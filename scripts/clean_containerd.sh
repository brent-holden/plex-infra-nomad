#!/usr/bin/env bash

echo "Cleaning all containers"
for i in `ctr --namespace nomad container ls -q`; do ctr --namespace nomad container rm $i; done
