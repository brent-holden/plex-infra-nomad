#!/bin/bash

/usr/bin/docker rm $(docker container ls -f status=exited -a -q) > /dev/null 2>&1
/usr/bin/docker image prune -f > /dev/null 2>&1
