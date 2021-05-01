#!/usr/bin/env bash
docker run --rm \
	--name jupyterjava_${PWD##*/} \
	--volume $PWD/notebooks:/notebooks \
        --volume $PWD/src:/src \
        --volume ~/.m2:/home/jovyan/.m2 \
        --volume $PWD/codeserver:/codeserver \
        --publish 8888:8888 \
        --env NB_UID=$UID \
	--env NOTEBOOK_SRC_SUBDIR=${PWD##*/} \
        brunoe/jupyterjava:feature_binder
