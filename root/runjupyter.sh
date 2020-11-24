#!/bin/zsh -l
export HOME=/home/user/

export SDK_MAN=/opt/sdkman

export IJAVA_COMPILER_OPTS="-deprecation"
export IJAVA_CLASSPATH="/home/user/lib/*.jar:/usr/local/bin/*.jar"
export IJAVA_STARTUP_SCRIPTS_PATH="/magics/*"
. /home/user/.zshrc
/opt/miniconda/etc/profile.d/conda.sh && conda activate py38

export PATH=/opt/bin:$PATH
export CODE_WORKINGDIR=/notebooks
export CODE_EXTENSIONSDIR=/opt/codeserverextensions

jupyter lab --notebook-dir=/notebooks --ip 0.0.0.0 --no-browser
