# Jupyter for Java
A docker image ton run a full learning environment for Java :
    - JDK : sdkman, java jdk LTS, the latest java 8 & the latest release, latest maven 3.
    - Shell Tools : bash, zsh, curl, git, vim
    - JupyterLab : miniconda, python 3.8, IJava Kernel, zsh kernel, app proxy (for codeserver), plant UML support, git extension, jupyter book for pdf generation.
    - codeserver : A web java editor with  java, sonarqube, lombok, plantUML and git support. 

## Usage

The docker images uses three volumes : '/notebooks' contains the notebooks, '/src' the source code created in the notebook outside of cells and '/codeserver' to store codeserver local changes.

Jupyter exposes the port 8888, the other apps (like code server) are proxied.

The image is run as the host user (PUID & PGID variables).

The default sudo password is "secret".

```shell
docker run \
        --name jupyterjava \
        --rm \
        --volume $PWD/notebooks:/notebooks \
        --volume $PWD/src:/src \
        --volume $PWD/codeserver:/codeserver \
        --publish 8888:8888 \
        --env PUID=$UID \
      	--env PGID=$GID \
      	--env SUDO_PASSWORD=secret \
        --volume ~/.m2:/home/user/.m2 \
        brunoe/jupyterjava:feature_codeserver
```

        --env MAVEN_CONFIG=/home/user/.m2 \
        --env MAVEN_OPTS="-Duser.home=/home/user/" \
