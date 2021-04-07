FROM debian:bullseye-slim

ARG NB_USER=jovyan
ARG NB_UID=1000

ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    	--gecos "Default user" \
	--uid "$NB_UID" \
	"$NB_USER" && \
    echo "$USER:$USER" | chpasswd && adduser "$USER" sudo

RUN apt-get update && apt-get install -y --no-install-recommends\
	bash \
	ca-certificates \
	coreutils \
	curl \
#	dns-utils \
	fonts-liberation \
	git \
	gnupg \
	graphviz ttf-bitstream-vera gsfonts \
	inkscape \
	less \
	locales \
	net-tools \
	openssh-client \
	pandoc \
	procps \
	python3-pip \
	sudo \
#	texlive-fonts-extra \
	texlive-fonts-recommended \
	texlive-lang-french \
#	texlive-latex-extra \
	texlive-plain-generic \	
	texlive-xetex \
	tree \
	tzdata \
	unzip \
	vim \
#	xz-libs \
	zip \
	zsh && \
  rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt && \
  echo en_US.UTF-8 UTF-8 >> /etc/locale.gen && \
  locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN echo -e "\e[93m***** Install Jupyter Lab ****\e[38;5;241m" && \
	curl -fsSL https://deb.nodesource.com/setup_15.x | bash - && \
	apt-get update && apt-get install -y --no-install-recommends nodejs gcc g++ make && \
	pip3 install --no-cache-dir --upgrade jupyter-book jupyterlab jupyter-server-proxy nbdime jupyterthemes&& \
#	jupyter labextension install @jupyterlab/server-proxy @jupyterlab/toc && \
	jupyter labextension install @jupyterlab/server-proxy && \
	nbdime extensions --enable && \
	npm cache clean --force && \
    	jupyter lab clean  

RUN echo -e "\e[93m**** Install Java Kernel for Jupyter ****\e[38;5;241m" && \
 	curl -sL https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o /tmp/ijava-kernel.zip && \
 	unzip /tmp/ijava-kernel.zip -d /tmp/ijava-kernel && \
  	cd /tmp/ijava-kernel && \
	python3 install.py --sys-prefix && \
  	# python3 install.py  && \
	# jupyter kernelspec install --user  java/ && \
  	cd && rm -rf /tmp/ijava-kernel /tmp/ijava-kernel.zip && \
    	echo -e "\e[93m**** Install ZSH Kernel for Jupyter ****\e[38;5;241m" && \
	python3 -mpip install notebook zsh_jupyter_kernel \
	&& python3 -mzsh_jupyter_kernel.install --sys-prefix 
COPY kernel.json /usr/share/jupyter/kernels/java/kernel.json

RUN echo -e "\e[93m**** Update Jupyter config ****\e[38;5;241m" && \
	mkdir -p $HOME/jupyter_data && \
	jupyter lab --generate-config && \
	sed -i -e '/c.ServerApp.disable_check_xsrf =/ s/= .*/= True/' \
	    -e 's/# \(c.ServerApp.disable_check_xsrf\)/\1/' \
	    -e '/c.ServerApp.data_dir =/ s/= .*/= "\/home\/jovyan\/jupyter_data"/' \
	    -e "/c.ServerApp.terminado_settings =/ s/= .*/= { 'shell_command': ['\/bin\/zsh'] }/" \
	    -e 's/# \(c.ServerApp.terminado_settings\)/\1/' \
	$HOME/.jupyter/jupyter_lab_config.py

RUN echo -e "\e[93m**** Install latest PlantUML ***\e[38;5;241m" && \
	curl -sL http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -o /usr/local/bin/plantuml.jar

ENV CODESERVEREXT_DIR /opt/codeserverextensions
ENV CODE_WORKINGDIR /src
RUN echo -e "\e[93m**** Installs Code Server Web ****\e[38;5;241m" && \
 	curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix=/opt --method=standalone && \
 	mkdir -p $CODESERVEREXT_DIR && \
	PATH=/opt/bin:$PATH code-server \
	--user-data-dir /codeserver \
        --extensions-dir $CODESERVEREXT_DIR \
	--install-extension vscjava.vscode-java-pack \
	--install-extension redhat.vscode-xml \
	--install-extension vscode-icons-team.vscode-icons \
	--install-extension SonarSource.sonarlint-vscode \
	--install-extension GabrielBB.vscode-lombok \
 	--install-extension jebbs.plantuml && \
	groupadd codeserver && \
        chgrp -R codeserver $CODESERVEREXT_DIR &&\
        chmod 770 -R $CODESERVEREXT_DIR && \
        adduser "$USER" codeserver


RUN echo -e "\e[93m**** Adds S6 scripts : services, user ids, ... ****\e[38;5;241m"
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.1/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
COPY /root /

COPY code-server/codeserver-jupyter_notebook_config.py /tmp/
COPY code-server/icons $HOME/.jupyter/icons
RUN cat /tmp/codeserver-jupyter_notebook_config.py >> $HOME/.jupyter/jupyter_notebook_config.py

############################################################"

## ZSH
ADD initzsh.sh /tmp/initzsh.sh
ADD p10k.zsh $HOME/.p10k.zsh 
RUN echo -e "\e[93m**** Configure a nice zsh environment ****\e[38;5;241m" && \
 	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && \
	zsh -c /tmp/initzsh.sh && \
	sed -i -e "s/zstyle ':prezto:module:prompt' theme 'sorin'/zstyle ':prezto:module:prompt' theme 'powerlevel10k'/" $HOME/.zpreztorc && \
	echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> $HOME/.zshrc && \
	echo "PATH=/opt/bin:$PATH" >> $HOME/.zshrc

SHELL ["/bin/zsh","-l","-c"]

RUN echo -e "\e[93m**** Installs SDKMan, Java JDKs and Maven3 ****\e[38;5;241m"
# Tool to easily install java dev tools.  
# global install of sdkman 
# Install java jdk LTS, the latest java 8 & the latest release
# Install the latest mvn 3
RUN curl -s "https://get.sdkman.io" | bash && \
    echo "sdkman_auto_answer=true" > $HOME/.sdkman/etc/config && \
	source "$HOME/.sdkman/bin/sdkman-init.sh" && \
#	sdk install java && \
#       for jdk_version in `sdk list java|grep '|'|grep "hs-adpt"|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|sed '1!G;h;$!d'`; do sdk install java $jdk_version; done && \ 
	for jdk_version in `sdk list java|grep '|'|grep "hs-adpt"|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do sdk install java $jdk_version; done && \
#        sdk install maven `sdk list maven|grep 3|head -n 1|sed -e 's/[^0-9]*\([0-9.]\+\)/\1/'` && \
	sdk install maven && \
#	sdk install mvnd && \
	sdk flush && \
	groupadd sdk && \
	chgrp -R sdk $SDKMAN_DIR &&\
	chmod 770 -R $SDKMAN_DIR && \	
	adduser $NB_USER sdk && \
	sdk flush && \
	sdk flush broadcast

ENV IJAVA_COMPILER_OPTS="-deprecation -Xlint -XprintProcessorInfo -XprintRounds "
ENV IJAVA_CLASSPATH="${HOME}/lib/*.jar:/usr/local/bin/*.jar"
ENV IJAVA_STARTUP_SCRIPTS_PATH="/magics/*"

RUN mkdir "${HOME}/lib/" && \
	curl -sL https://projectlombok.org/downloads/lombok.jar -o "${HOME}/lib/lombok.jar"

COPY dependencies/* "$HOME/lib/" 

# Adds IJava Jupyter Kernel Personnal Magics
ADD magics  /magics

RUN echo -e "\e[93m**** Install Java Kernel for Jupyter ****\e[38;5;241m" && \
        curl -sL https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o /tmp/ijava-kernel.zip && \
        unzip /tmp/ijava-kernel.zip -d /tmp/ijava-kernel && \
        cd /tmp/ijava-kernel && \
        python3 install.py --sys-prefix && \
        cd && rm -rf /tmp/ijava-kernel /tmp/ijava-kernel.zip && \
        echo -e "\e[93m**** Install ZSH Kernel for Jupyter ****\e[38;5;241m" && \
        python3 -m pip install notebook zsh_jupyter_kernel && \
        python3 -m zsh_jupyter_kernel.install --sys-prefix

# COPY kernel-2.json /home/jovyan/.local/share/jupyter/kernels/java/kernel.json

RUN echo 'JAVA_HOME=/home/jovyan/.sdkman/candidates/java/current' >> /etc/environment  && \
	echo 'PATH=/home/jovyan/.sdkman/candidates/maven/current/bin:/home/jovyan/.sdkman/candidates/java/current/bin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /etc/environment && \
	chsh -s /usr/bin/zsh jovyan

#CMD chmod o+w /usr/local/lib/python3.9/dist-packages/zsh_jupyter_kernel/log/

EXPOSE 8888
ENTRYPOINT ["/init"]

WORKDIR /notebooks
