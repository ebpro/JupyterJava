#!/bin/bash

. ./env.sh

BASE=${REGISTRY}/${IMAGE_NAME}
BRANCH=`git rev-parse --abbrev-ref HEAD`

docker build \
	-t ${BASE}:`git log -1 --pretty=%h` \
	-t ${BASE}:`git rev-parse --abbrev-ref HEAD` \
	`[[ "$BRANCH" == "master" ]] && -t ${BASE}:latest` \
	 .
