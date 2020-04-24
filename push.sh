#!/bin/bash

. ./env.sh

BASE=${REGISTRY}/${IMAGE_NAME}
BRANCH=`git rev-parse --abbrev-ref HEAD`

docker push ${BASE}:`git log -1 --pretty=%h`
docker push ${BASE}:`git rev-parse --abbrev-ref HEAD`
docker push `[[ "$BRANCH" == "master" ]] && -t ${BASE}:latest`
	 .
