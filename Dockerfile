################# SDKMAN STAGE ################
FROM ubuntu:focal AS BASE
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --quiet --assume-yes --no-install-recommends \
	apt-utils \
	bash \
	ca-certificates \
	curl \
	fonts-wqy-zenhei \
	git \
	init \
	less \
	locales \
	openssh-client \
	tzdata \
	unzip \
	vim \
	vim-latexsuite \
	xz-utils \
	zip \
	zsh \
	&& \
 locale-gen fr_FR.UTF-8 && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

RUN echo "\e[93m**** Install S6 supervisor ****\e[38;5;241m" && \
	curl -L https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer -o /tmp/s6-overlay-amd64-installer && \
	chmod +x /tmp/s6-overlay-amd64-installer && \
	/tmp/s6-overlay-amd64-installer / && \
	rm /tmp/s6-overlay-amd64-installer && \
 	mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
	echo "\e[93m**** Create user 'user' ****\e[38;5;241m" && \
 	useradd -u 2000 -U -s /usr/bin/zsh -m user && \
 	usermod -G users user && \
	mkdir /home/user/lib

ENV HOME "/home/user"

# mv $HOME/.zshrc $HOME/.zshrc.orig && \
	# cat $HOME/.zshrc.orig >> $HOME/.zshrc && \
	# rm $HOME/.zshrc.orig && \
RUN echo -e "\e[93m**** Configure a nice zsh environment ****\e[38;5;241m"
ADD initzsh.sh /tmp/initzsh.sh
ADD p10k.zsh /home/user/.p10k.zsh 
RUN git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && \
	zsh -c /tmp/initzsh.sh && \
	sed -i -e "s/zstyle ':prezto:module:prompt' theme 'sorin'/zstyle ':prezto:module:prompt' theme 'powerlevel10k'/" $HOME/.zpreztorc
SHELL ["/bin/bash","-l","-c"]
CMD zsh

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
        for jdk_version in `sdk list java|grep '|'|grep "hs-adpt"|tr -s ' '|cut -d '|' -f 6|sed -e 's/^[[:space:]]*/ /g'|sed -e 1b -e '$!d'|sed '1!G;h;$!d'`; \
		do sdk install java $jdk_version; done && \ 
        sdk install maven `sdk list maven|grep 3|head -n 1|sed -e 's/[^0-9]*\([0-9.]\+\)/\1/'` && \
	sdk install mvnd && \
	sdk flush && \
	groupadd sdk && \
	chgrp -R sdk $SDKMAN_DIR &&\
	chmod 770 -R $SDKMAN_DIR && \	
	adduser user sdk
	
################# JUPYTER JAVA ################
FROM BASE

RUN echo "\e[93m**** Install packages and sets locale ****\e[38;5;241m" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --quiet --assume-yes --no-install-recommends \
	graphviz \
	inkscape \
	pandoc \
	texlive-fonts-recommended \
	texlive-fonts-extra \
	texlive-lang-french \
	texlive-latex-extra \
	texlive-xetex \
	tree \
	&& \
 locale-gen fr_FR.UTF-8 && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

ENV CONDA_HOME "/opt/miniconda"
RUN echo -e "\e[93m**** Install & update conda ****\e[38;5;241m" && \
	curl -s https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
	bash /tmp/miniconda.sh -b -p $CONDA_HOME && \
	eval "$($CONDA_HOME/bin/conda shell.bash hook)" && \
	conda update -n base -c defaults conda && \
	conda create --name py38 python=3.8 && \
	conda activate py38 && \
	conda init bash && \
	conda init zsh && \
	rm -rf /tmp/miniconda.sh && \
	groupadd conda && \
	chgrp -R conda $CONDA_HOME &&\
	chmod 770 -R $CONDA_HOME && \	
	adduser user conda

RUN echo -e "\e[93m***** Install Jupyter Lab ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	conda install -c conda-forge jupyterlab && \
	conda install -c conda-forge jupyterthemes && \
    echo -e "\e[93m**** Install Java Kernel for Jupyter ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
 	curl -sL https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o /tmp/ijava-kernel.zip && \
 	unzip /tmp/ijava-kernel.zip -d /tmp/ijava-kernel && \
  	cd /tmp/ijava-kernel && \
  	python3 install.py  &&\
  	cd && rm -rf /tmp/ijava-kernel /tmp/ijava-kernel.zip && \
    echo -e "\e[93m**** Install ZSH Kernel for Jupyter ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	python3 -mpip install notebook zsh_jupyter_kernel \
	&& python3 -mzsh_jupyter_kernel.install --sys-prefix 

RUN echo -e "\e[93m**** Install Jupyter app proxy ****\e[38;5;241m" && \ 
 	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 &&  \
	conda install -c conda-forge nodejs && \
	conda update --all  && \
	conda install -c conda-forge jupyter-server-proxy && \
	jupyter labextension install @jupyterlab/server-proxy

# Install Jupyterlab git extension
#RUN jupyter labextension install @jupyterlab/git && \
#	pip3 install --upgrade jupyterlab-git && \
RUN echo -e "\e[93m**** Install jupyterlab git extension ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	conda install -c conda-forge jupyterlab jupyterlab-git && \
	jupyter lab build && \
	jupyter serverextension enable --py jupyterlab_git

# Install nbdim extension
RUN echo -e "\e[93m**** Install jupyterlab nbdime git extension ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	conda install -c conda-forge nbdime && \ 
	jupyter serverextension enable --py nbdime && \
	jupyter nbextension install --py nbdime && \
	jupyter nbextension enable --py nbdime && \
        jupyter labextension install nbdime-jupyterlab 

# Install toc extension
RUN echo -e "\e[93m**** Install jupyterlab toc extension ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	jupyter labextension install @jupyterlab/toc

RUN echo -e "\e[93m**** Update Jupyter config ****\e[38;5;241m" && \
	mkdir -p /home/user/jupyter_data && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	jupyter lab --generate-config && \
	sed -i -e '/c.LabApp.disable_check_xsrf =/ s/= .*/= True/' \
	    -e 's/# \(c.LabApp.disable_check_xsrf\)/\1/' \
	    -e '/c.LabApp.data_dir =/ s/= .*/= "\/home\/user\/jupyter_data"/' \
	    -e "/c.LabApp.terminado_settings =/ s/= .*/= { 'shell_command': ['\/usr\/bin\/zsh'] }/" \
	    -e 's/# \(c.LabApp.terminado_settings\)/\1/' \
	/home/user/.jupyter/jupyter_notebook_config.py

RUN echo -e "\e[93m**** Install Jupyter book ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	pip3 install --no-cache-dir -U jupyter-book

RUN echo -e "\e[93m**** Install nbgrader ****\e[38;5;241m" && \
	. $CONDA_HOME/etc/profile.d/conda.sh && conda activate py38 && \
	conda install -c conda-forge nbgrader && \
	jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
	jupyter nbextension enable --sys-prefix --py nbgrader && \
	jupyter serverextension enable --sys-prefix --py nbgrader

# Adds IJava Jupyter Kernel Personnal Magics
ADD magics  /magics

RUN echo -e "\e[93m**** Install latest PlantUML ***\e[38;5;241m" && \
	curl -sL http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -o /usr/local/bin/plantuml.jar

WORKDIR /notebooks

RUN echo -e "\e[93m**** Installs SDKMan, Java JDKs and Maven3 ****\e[38;5;241m"
COPY --from=SDKMAN /opt/sdkman /opt/sdkman

RUN echo "/opt/miniconda/etc/profile.d/conda.sh && conda activate py38" >> $HOME/.zshrc && \
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
 	--install-extension plantuml && \
	mkdir -p /home/user/.config && \
	mv ~/.config/code-server && /home/user/.config && \
	groupadd codeserver && \
        chgrp -R codeserver $CODESERVEREXT_DIR &&\
        chmod 770 -R $CODESERVEREXT_DIR && \
        adduser user codeserver

RUN echo -e "\e[93m**** Adds S6 scripts : services, user ids, ... ****\e[38;5;241m"
COPY /root /

RUN echo -e "\e[93m**** Enable Java assertions and previews ****\e[38;5;241m"
COPY kernel.json /usr/share/jupyter/kernels/java/kernel.json

COPY code-server/codeserver-jupyter_notebook_config.py /tmp/
COPY code-server/icons /home/user/.jupyter/icons
RUN cat /tmp/codeserver-jupyter_notebook_config.py >> /home/user/.jupyter/jupyter_notebook_config.py

RUN echo 'export M2_HOME=$MAVEN_HOME' >> $HOME/.zshrc 

ENTRYPOINT ["/init"]
