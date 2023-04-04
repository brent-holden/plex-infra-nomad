#!/usr/bin/env bash

if [ ! -n "$1" ]; then
    echo "Add a version to build, like v1.0"
    exit
fi

cd update-services
sudo docker build -t bholden/update-services .
sudo docker tag bholden/update-services:latest bholden/update-services:$1
sudo docker push bholden/update-services:$1
sudo docker push bholden/update-services:latest

