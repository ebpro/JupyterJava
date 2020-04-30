#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. ${DIR}/env.sh

echo $BASE:$SHA

docker run --rm -it \
	-v $PWD:/notebooks \
	-w /tmp  \
	-p 8888:8888 \
	-v ~/.m2:/var/maven/.m2 \
	-e MAVEN_CONFIG=/var/maven/.m2 \
	-e MAVEN_OPTS="-Duser.home=/var/maven" \
	${BASE}:${SHA} 
	
