# Jupyter for Java

A docker image ton run a full learning environment for Java in a Jupyter notebook :

* JDK : The latest jdk installed with sdkman and the latest maven 3.
* Shell Tools : bash, zsh, curl, Git, vim.
* JupyterLab : miniconda, python 3.8, IJava Kernel, zsh kernel, app proxy (for codeserver), plant UML support, git extension, jupyter book for pdf generation.
* Codeserver : A web editor with  java, sonarqube, lombok, plantUML and Git support. 

## Usage

The docker images uses one volume : `/home/jovyan/work` which contains subdirectories :

* `notebooks/` :  the notebooks, 
* `src/` : the source code created in the notebook outside of cells (by git for example),
* `codeserver/` to store codeserver local changes,
* `.m2` to store a maven repository.

Jupyter exposes the port 8888, the other apps (like code server) are proxied.

The image is run as the host user (PUID & PGID variables).

The default sudo password is "secret".

```shell
docker run --rm \
       --name JupyterJava \
       --volume $PWD/notebooks:/home/jovyan/work \
        --publish 8888:8888 \
        --env NB_UID=$UID \
        --env JUPYTER_ENABLE_LAB=yes \
        brunoe/jupyterjava:develop
```
