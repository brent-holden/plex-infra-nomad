#!/usr/bin/env bash

if [ ! -n "$1" ]; then
    echo "Add a version to build, like v1.0"
    exit
fi

cd update-services
docker build -t bholden/update-services .
docker tag bholden/update-services:latest bholden/update-services:$1
docker push bholden/update-services:$1
docker push bholden/update-services:latest

