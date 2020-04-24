# https://github.com/SpencerPark/ijava-binder/blob/master/Dockerfile
FROM maven:3.6.3-jdk-11-openj9

RUN apt-get update && \
    apt-get install --quiet --assume-yes python3-pip unzip zsh git vim \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# add requirements.txt and install jupyter lab
COPY requirements.txt . 
RUN pip3 install --no-cache-dir -r requirements.txt jupyter jupyterlab

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

CMD ["jupyter","lab","--notebook-dir=/notebooks","--ip","0.0.0.0","--no-browser","--allow-root"]
