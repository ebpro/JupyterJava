################# BASE STAGE ################
FROM alpine:3.13.1 AS BASE

ENV S6_OVERLAY_VERSION 2.2.0.1

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.30-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    mkdir /tmp/zlib && \ 
    wget https://www.archlinux.org/packages/core/x86_64/zlib/download/ -O /tmp/zlib/zlib.tar.xz && \
    cd /tmp/zlib && tar xvf zlib.tar.xz && \
    cp -r usr/* /usr/glibc-compat/ && \
    cd .. && rm -rf zlib && \
    apk add --no-cache \
	bash \
	bind-tools \
	ca-certificates \
	coreutils \
	curl \
#	wqy-zenhei \
	git \
	gnupg \
#	init \
	less \
#	locales \
	net-tools \
	openssh-client \
	shadow \
	tzdata \
	unzip \
	vim \
#	vim-latexsuite \
	xz-libs \
	zip \
	zsh \
   && rm -rf /var/cache/apk/*
COPY s6-overlay-key.asc /tmp
RUN echo "\e[93m**** Install S6 supervisor ****\e[38;5;241m" && \
	curl -L https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz  -o /tmp/s6-overlay-amd64.tar.gz && \
	curl -L https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz.sig  -o /tmp/s6-overlay-amd64.tar.gz.sig && \
	gpg --import /tmp/s6-overlay-key.asc && \
	gpg --verify /tmp/s6-overlay-amd64.tar.gz.sig /tmp/s6-overlay-amd64.tar.gz && \
	tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
	rm /tmp/s6-overlay-amd64.tar.gz && \
	rm /tmp/s6-overlay-amd64.tar.gz.sig && \
 	mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
	echo "\e[93m**** Create user 'user' ****\e[38;5;241m" && \
	useradd -u 2000 -U -s /bin/zsh -m user && \
 	usermod -G users user && \
	mkdir /home/user/lib

ENV HOME "/home/user"

RUN echo -e "\e[93m**** Configure a nice zsh environment ****\e[38;5;241m"
ADD initzsh.sh /tmp/initzsh.sh
ADD p10k.zsh /home/user/.p10k.zsh 
RUN git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && \
	zsh -c /tmp/initzsh.sh && \
	sed -i -e "s/zstyle ':prezto:module:prompt' theme 'sorin'/zstyle ':prezto:module:prompt' theme 'powerlevel10k'/" $HOME/.zpreztorc
SHELL ["/bin/bash","-l","-c"]
CMD zsh
#---------------- BASE STAGE ------------------
################# SDKMAN STAGE ################
FROM BASE AS SDKMAN

RUN echo -e "\e[93m**** Installs SDKMan, Java JDKs and Maven3 ****\e[38;5;241m"
# Tool to easily install java dev tools.  
# global install of sdkman 
ENV SDKMAN_DIR="/opt/sdkman"
RUN curl -s "https://get.sdkman.io" | bash && \
    echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config
# Install java jdk LTS, the latest java 8 & the latest release
# Install the latest mvn 3
RUN     source "/opt/sdkman/bin/sdkman-init.sh" && \
	sdk install java && \
#        for jdk_version in `sdk list java|grep '|'|grep "hs-adpt"|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|sed '1!G;h;$!d'`; do sdk install java $jdk_version; done && \ 
	sdk install java && \
        sdk install maven `sdk list maven|grep 3|head -n 1|sed -e 's/[^0-9]*\([0-9.]\+\)/\1/'` && \
	sdk install mvnd && \
	sdk flush && \
	groupadd sdk && \
	chgrp -R sdk $SDKMAN_DIR &&\
	chmod 770 -R $SDKMAN_DIR && \	
	adduser user sdk && \
	sdk flush && \
	sdk flush broadcast
#---------------- SDK MAN STAGE --------------
	
################# JUPYTER JAVA STAGE ################
FROM BASE
RUN echo "\e[93m**** Install packages and sets locale ****\e[38;5;241m" && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing pandoc && \
    apk add --no-cache \
	graphviz font-bitstream-type1 ghostscript-fonts \
	inkscape \
#	texlive-fonts-recommended \
#	texlive-fonts-extra \
#	texlive-lang-french \
#	texlive-latex-extra \
	texlive-xetex \
	tree \
    && rm -rf /var/cache/apk/*

ARG CONDA_VERSION=py38_4.9.2
ARG CONDA_MD5=122c8c9beb51e124ab32a0fa6426c656
ENV PATH /opt/conda/bin:$PATH
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda.sh && \
    echo "${CONDA_MD5}  miniconda.sh" > miniconda.md5 && \
    if ! md5sum -c miniconda.md5; then exit 1; fi && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh miniconda.md5 && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.shinit && \
    echo "conda activate base" >> ~/.shinit && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy && \
    /opt/conda/bin/conda init bash && \
    /opt/conda/bin/conda init zsh 
 
RUN echo -e "\e[93m***** Install Jupyter Lab ****\e[38;5;241m" && \
	conda activate base && \
	conda install -c conda-forge jupyterlab jupyterthemes nodejs jupyter-server-proxy jupyterlab-git nbgrader && \
	conda update --all  && \
	jupyter labextension install @jupyterlab/server-proxy nbdime-jupyterlab @jupyterlab/toc && \ 
	jupyter lab build && \
	conda clean -afy && \
	find /opt/conda/ -follow -type f -name '*.a' -delete && \
    	find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
    	find /opt/conda/ -follow -type f -name '*.js.map' -delete 
#    	find /opt/conda/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete

#        jupyter serverextension enable --py jupyterlab_git && \
#	jupyter serverextension enable --py nbdime && \
#        jupyter nbextension install --py nbdime && \
#        jupyter nbextension enable --py nbdime && \
#	jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
#	jupyter nbextension enable --sys-prefix --py nbgrader && \
#	jupyter serverextension enable --sys-prefix --py nbgrader

RUN echo -e "\e[93m**** Install Java Kernel for Jupyter ****\e[38;5;241m" && \
	conda activate base && \
 	curl -sL https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o /tmp/ijava-kernel.zip && \
 	unzip /tmp/ijava-kernel.zip -d /tmp/ijava-kernel && \
  	cd /tmp/ijava-kernel && \
  	python install.py  &&\
  	cd && rm -rf /tmp/ijava-kernel /tmp/ijava-kernel.zip && \
    	echo -e "\e[93m**** Install ZSH Kernel for Jupyter ****\e[38;5;241m" && \
	python -mpip install notebook zsh_jupyter_kernel \
	&& python -mzsh_jupyter_kernel.install --sys-prefix 

# RUN echo -e "\e[93m**** Install Jupyter app proxy ****\e[38;5;241m" && \ 
# 	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 &&  \
##	conda activate base && \
##	conda install -c conda-forge nodejs && \
##	conda update --all  && \
##	conda install -c conda-forge jupyter-server-proxy && \
##	jupyter labextension install @jupyterlab/server-proxy

# Install Jupyterlab git extension
#RUN jupyter labextension install @jupyterlab/git && \
#	pip3 install --upgrade jupyterlab-git && \
# RUN echo -e "\e[93m**** Install jupyterlab git extension ****\e[38;5;241m" && \
#	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
#	conda activate base && \
#	conda install -c conda-forge jupyterlab jupyterlab-git && \
#	jupyter lab build && \
#	jupyter serverextension enable --py jupyterlab_git

# Install nbdim extension
# RUN echo -e "\e[93m**** Install jupyterlab nbdime git extension ****\e[38;5;241m" && \
#	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
#	conda activate base && \
#	conda install -c conda-forge nbdime && \ 
#	jupyter serverextension enable --py nbdime && \
#	jupyter nbextension install --py nbdime && \
#	jupyter nbextension enable --py nbdime && \
 #       jupyter labextension install nbdime-jupyterlab 

# Install toc extension
#RUN echo -e "\e[93m**** Install jupyterlab toc extension ****\e[38;5;241m" && \
#	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
#	conda activate base && \
#	jupyter labextension install @jupyterlab/toc

RUN echo -e "\e[93m**** Update Jupyter config ****\e[38;5;241m" && \
	mkdir -p /home/user/jupyter_data && \
	conda activate base && \
	jupyter lab --generate-config && \
	sed -i -e '/c.LabApp.disable_check_xsrf =/ s/= .*/= True/' \
	    -e 's/# \(c.LabApp.disable_check_xsrf\)/\1/' \
	    -e '/c.LabApp.data_dir =/ s/= .*/= "\/home\/user\/jupyter_data"/' \
	    -e "/c.LabApp.terminado_settings =/ s/= .*/= { 'shell_command': ['\/bin\/zsh'] }/" \
	    -e 's/# \(c.LabApp.terminado_settings\)/\1/' \
	/home/user/.jupyter/jupyter_notebook_config.py

RUN echo -e "\e[93m**** Install Jupyter book ****\e[38;5;241m" && \
	conda activate base && \
	pip3 install --no-cache-dir -U jupyter-book && \
	jupyter lab build && \
	conda clean -afy && \
        find /opt/conda/ -follow -type f -name '*.a' -delete && \
        find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
        find /opt/conda/ -follow -type f -name '*.js.map' -delete 
#        find /opt/conda/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete
 

RUN echo -e "\e[93m**** Install latest PlantUML ***\e[38;5;241m" && \
	curl -sL http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -o /usr/local/bin/plantuml.jar

RUN echo "conda activate base" >> $HOME/.zshrc && \
	echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> $HOME/.zshrc && \
	echo "export SDKMAN_DIR=/opt/sdkman >> $HOME/.zshrc" >> $HOME/.zshrc && \
	echo "[[ ! -f /opt/sdkman/bin/sdkman-init.sh ]] || source /opt/sdkman/bin/sdkman-init.sh" >> $HOME/.zshrc

RUN echo -e "\e[93m**** Installs Code Server Web ****\e[38;5;241m"
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix=/opt --method=standalone 
ENV CODESERVEREXT_DIR /opt/codeserverextensions
RUN mkdir -p $CODESERVEREXT_DIR && \
	PATH=/opt/bin:$PATH code-server \
	--user-data-dir /codeserver \
        --extensions-dir $CODESERVEREXT_DIR \
	--install-extension vscjava.vscode-java-pack \
	--install-extension vscode-icons-team.vscode-icons \
	--install-extension SonarSource.sonarlint-vscode \
	--install-extension GabrielBB.vscode-lombok \
 	--install-extension jebbs.plantuml && \
	#mkdir -p /home/user/.config && \
	#mv ~/.config/code-server /home/user/.config && \
	groupadd codeserver && \
        chgrp -R codeserver $CODESERVEREXT_DIR &&\
        chmod 770 -R $CODESERVEREXT_DIR && \
        adduser user codeserver

#---------------------------- JUPYTER STAGE --------------------------
############################# FINAL STAGE ############################

RUN echo -e "\e[93m**** Installs SDKMan, Java JDKs and Maven3 ****\e[38;5;241m"
COPY --from=SDKMAN /opt/sdkman /opt/sdkman

# Adds IJava Jupyter Kernel Personnal Magics
ADD magics  /magics

WORKDIR /notebooks

RUN echo -e "\e[93m**** Adds S6 scripts : services, user ids, ... ****\e[38;5;241m"
COPY /root /

RUN echo -e "\e[93m**** Enable Java assertions and previews ****\e[38;5;241m"
COPY kernel.json /usr/share/jupyter/kernels/java/kernel.json

COPY code-server/codeserver-jupyter_notebook_config.py /tmp/
COPY code-server/icons /home/user/.jupyter/icons
RUN cat /tmp/codeserver-jupyter_notebook_config.py >> /home/user/.jupyter/jupyter_notebook_config.py

RUN echo 'export M2_HOME=$MAVEN_HOME' >> $HOME/.zshrc 

ENTRYPOINT ["/init"]
