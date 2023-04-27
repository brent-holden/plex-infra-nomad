#!/usr/bin/env bash

if [ ! -n "$1" ]; then
    echo "Add a service to build, like update-services"
    exit
fi

if [ ! -n "$2" ]; then
    echo "Add a version to build, like v1.0"
    exit
fi

cd $1
docker build -t bholden/$1 .
docker tag bholden/$1:latest bholden/$1:$2
docker push bholden/$1:$2
docker push bholden/$1:latest

