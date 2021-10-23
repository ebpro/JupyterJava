ARG BASE_CONTAINER=brunoe/jupyterutln-default:develop
FROM $BASE_CONTAINER

LABEL maintainer="Emmanuel Bruno <emmanuel.bruno@univ-tln.fr>"

USER root

# Install minimal dependencies 
RUN apt-get update && apt-get install -y --no-install-recommends\
	coreutils \
	dnsutils \
	gnupg \
	graphviz ttf-bitstream-vera gsfonts \
	inkscape \
	iputils-ping \
	net-tools \
	pandoc \
	procps \
	tree \
	zsh && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt 

## ZSH
ADD zsh/initzsh.sh /tmp/initzsh.sh
ADD zsh/p10k.zsh $HOME/.p10k.zsh 

RUN echo -e "\e[93m**** Install Java Kernel for Jupyter ****\e[38;5;241m" && \
        curl -sL https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o /tmp/ijava-kernel.zip && \
        unzip /tmp/ijava-kernel.zip -d /tmp/ijava-kernel && \
        cd /tmp/ijava-kernel && \
        python3 install.py --sys-prefix && \
	# jupyter kernelspec install --user java/ && \
        cd && rm -rf /tmp/ijava-kernel /tmp/ijava-kernel.zip && \
    echo -e "\e[93m**** Install ZSH Kernel for Jupyter ****\e[38;5;241m" && \
        python3 -m pip install zsh_jupyter_kernel && \
        python3 -m zsh_jupyter_kernel.install --sys-prefix && \
    echo -e "\e[93m**** Update Jupyter config ****\e[38;5;241m" && \
	mkdir -p $HOME/jupyter_data && \
	jupyter lab --generate-config && \
	sed -i -e '/c.ServerApp.disable_check_xsrf =/ s/= .*/= True/' \
	    -e 's/# \(c.ServerApp.disable_check_xsrf\)/\1/' \
	    -e '/c.ServerApp.data_dir =/ s/= .*/= "\/home\/jovyan\/jupyter_data"/' \
	    -e "/c.ServerApp.terminado_settings =/ s/= .*/= { 'shell_command': ['\/bin\/zsh'] }/" \
	    -e 's/# \(c.ServerApp.terminado_settings\)/\1/' \
	$HOME/.jupyter/jupyter_lab_config.py && \ 
    echo -e "\e[93m**** Configure a nice zsh environment ****\e[38;5;241m" && \
 	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && \
	zsh -c /tmp/initzsh.sh && \
	sed -i -e "s/zstyle ':prezto:module:prompt' theme 'sorin'/zstyle ':prezto:module:prompt' theme 'powerlevel10k'/" $HOME/.zpreztorc && \
	echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> $HOME/.zshrc && \
	echo "PATH=/opt/bin:$PATH" >> $HOME/.zshrc && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

## Enable Java Early Access
#COPY kernel.json /opt/conda/share/jupyter/kernels/java/kernel.json
# Adds IJava Jupyter Kernel Personnal Magics
ADD magics  /magics

ENV IJAVA_COMPILER_OPTS="-deprecation -Xlint -XprintProcessorInfo -XprintRounds "
ENV IJAVA_CLASSPATH="${HOME}/lib/*.jar:/usr/local/bin/*.jar"
ENV IJAVA_STARTUP_SCRIPTS_PATH="/magics/*"

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
#	for jdk_version in `sdk list java|grep '|'|grep "hs-adpt"|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do sdk install java $jdk_version; done && \
	for jdk_version in `sdk list java|grep '|'|grep -- "-tem"|grep 8|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do sdk install java $jdk_version; done && \
	for jdk_version in `sdk list java|grep '|'|grep -- "-tem"|grep 11|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do sdk install java $jdk_version; done && \
	for jdk_version in `sdk list java|grep '|'|grep -- "-tem"|grep 17|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|head -1`; do sdk install java $jdk_version; done && \
#        sdk install maven `sdk list maven|grep 3|head -n 1|sed -e 's/[^0-9]*\([0-9.]\+\)/\1/'` && \
	sdk install maven && \
#	sdk install mvnd && \
	sdk flush && \
	groupadd sdk && \
	chgrp -R sdk $SDKMAN_DIR &&\
	chmod 770 -R $SDKMAN_DIR && \	
	adduser $NB_USER sdk && \
	sdk flush && \
	sdk flush broadcast && \
	fix-permissions /home/$NB_USER 

RUN echo -e "\e[93m**** Install latest PlantUML, lombok and java dependencies ***\e[38;5;241m" && \
	mkdir "${HOME}/lib/" && \
	curl -sL http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -o "${HOME}/lib/plantuml.jar" && \
	curl -sL https://projectlombok.org/downloads/lombok.jar -o "${HOME}/lib/lombok.jar"
COPY dependencies/* "$HOME/lib/" 

# Adds Java and Maven to the user path
ENV PATH=/home/jovyan/.sdkman/candidates/maven/current/bin:/home/jovyan/.sdkman/candidates/java/current/bin:$PATH

RUN echo \
    "<settings xmlns='http://maven.apache.org/SETTINGS/1.2.0' \
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' \
    xsi:schemaLocation='http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd'> \
        <localRepository>\${user.home}/work/.m2/repository</localRepository> \
    </settings>" \
    > $HOME/.sdkman/candidates/maven/current/conf/settings.xml && \
    ln -s /home/jovyan/work/.m2 /home/jovyan/.m2

RUN echo '#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!' >> $HOME/.zshenv && \
    echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> $HOME/.zshenv && \
    echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> $HOME/.zshenv

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
# RUN mkdir -p /home/jovyan/.ssh && ssh-keyscan -t rsa github.com > /home/jovyan/.ssh/known_hosts
WORKDIR /home/jovyan
