# https://github.com/SpencerPark/ijava-binder/blob/master/Dockerfile
FROM maven:3.6.3-adoptopenjdk-14

RUN apt-get update && \
    apt-get install --quiet --assume-yes --no-install-recommends \
	python3-pip python3-setuptools unzip zsh git vim xz-utils graphviz fonts-wqy-zenhei inkscape texlive-xetex texlive-fonts-recommended texlive-generic-recommended pandoc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# add requirements.txt and install jupyter lab
#COPY requirements.txt . 
#RUN pip3 install --no-cache-dir -r requirements.txt jupyter jupyterlab
RUN pip3 install --no-cache-dir jupyter jupyterlab

USER root

# Download the Java ikernel release
RUN curl -L https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip > ijava-kernel.zip
# Unpack and install the java kernel
RUN unzip ijava-kernel.zip -d ijava-kernel \
  && cd ijava-kernel \
  && python3 install.py --sys-prefix

# Install the zsh kernel
RUN python3 -m pip install notebook zsh_jupyter_kernel \
	&& python3 -m zsh_jupyter_kernel.install --sys-prefix

RUN curl -L https://nodejs.org/dist/v12.16.1/node-v12.16.1-linux-x64.tar.xz > node.tgz && \
  tar xJf node.tgz -C /usr/local --strip-components=1 --no-same-owner && rm node.tgz && \
  ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
  node --version && \
  npm --version

RUN jupyter labextension install @jupyterlab/toc

# Set up the user environment

# ENV NB_USER jovyan
# ENV NB_UID 1000
# ENV HOME /home/$NB_USER

# RUN adduser --disabled-password \
#    --gecos "Default user" \
#    --uid $NB_UID \
#    $NB_USER

#COPY . $HOME
#RUN chown -R $NB_UID $HOME

#USER $NB_USER

# Launch the notebook server
#WORKDIR $HOME
# CMD ["jupyter", "lab", "--ip", "0.0.0.0"]

# Configure a nice zsh environment
RUN git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
ADD initzsh.sh .
RUN ./initzsh.sh


#Adds plantuml
# tagged for stability ?
# http://sourceforge.net/projects/plantuml/files/plantuml.1.2020.8.jar/download
RUN curl -L http://sourceforge.net/projects/plantuml/files/plantuml.jar/download > /usr/local/bin/plantuml.jar

ENV IJAVA_COMPILER_OPTS "--enable-preview -source 14"

#Enable assertions and previews
COPY kernel.json /usr/share/jupyter/kernels/java/kernel.json

RUN jupyter labextension install jupyterlab_hidecode

RUN pip3 install jupyterlab_latex && \
	jupyter labextension install @jupyterlab/latex

RUN jupyter labextension install @aquirdturtle/collapsible_headings

RUN pip3 install --upgrade jupyterlab-git && \
	jupyter lab build

RUN pip3 install jupyterlab_sql && \
	jupyter serverextension enable jupyterlab_sql --py --sys-prefix

CMD ["jupyter","lab","--notebook-dir=/notebooks","--ip","0.0.0.0","--no-browser","--allow-root"]
