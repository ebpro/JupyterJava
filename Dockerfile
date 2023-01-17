# syntax = docker/dockerfile:1.4.0
ARG BASE_CONTAINER=brunoe/jupyterjava-base:develop
FROM $BASE_CONTAINER

LABEL maintainer="Emmanuel Bruno <emmanuel.bruno@univ-tln.fr>"

USER root

RUN --mount=type=cache,target=/home/jovyan/.sdkman/archives/ \
	echo -e "\e[93m**** Adds JDK 8, 11 and 19****\e[38;5;241m" && \
	for target_version in 8 11 19; do \
		for jdk_version in `sdk list java|grep '|'|grep -- "-tem"|grep $target_version|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do \
			sdk install java $jdk_version; \
		done; \
	done && \
#	sdk flush && \
	chgrp -R sdk $SDKMAN_DIR && \
	chmod 770 -R $SDKMAN_DIR && \	
#	sdk flush && \
	sdk flush broadcast && \
	sdk default java `sdk list java|grep installed|cut -d '|' -f 6|head -1` && \
	fix-permissions /home/$NB_USER/.sdkman 

RUN echo -e "\e[93m**** Install lombok and java dependencies ***\e[38;5;241m" && \
	mkdir -p "${HOME}/lib/" && \
	curl -sL https://projectlombok.org/downloads/lombok.jar -o "${HOME}/lib/lombok.jar"
COPY dependencies/* "$HOME/lib/" 

#ENV IJAVA_COMPILER_OPTS="-deprecation -Xlint -XprintProcessorInfo -XprintRounds --enable-preview -source 19"

COPY kernel.json /opt/conda/share/jupyter/kernels/java/kernel.json

RUN pip install "jupyterlab-myst[eval]" sphinxcontrib-plantuml
#RUN <<EOF cat > /usr/local/bin/plantuml
#!/bin/sh -e
#java -jar /path/to/plantuml.jar "$@"
#EOF 
#RUN chmod +x /usr/local/bin/plantuml

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID

#ENV IJAVA_COMPILER_OPTS="-deprecation -Xlint -XprintProcessorInfo -XprintRounds --enable-preview -source 19"

