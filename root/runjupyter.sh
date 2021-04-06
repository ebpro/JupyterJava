#!/usr/bin/with-contenv /bin/zsh  
#export HOME=/home/user/

#export SDK_MAN=/opt/sdkman

#export IJAVA_COMPILER_OPTS="-deprecation"
#export IJAVA_CLASSPATH="/home/user/lib/*.jar:/usr/local/bin/*.jar"
#export IJAVA_STARTUP_SCRIPTS_PATH="/magics/*"
. $HOME/.zshrc

#export PATH=/opt/bin:$PATH
#export CODE_WORKINGDIR=/src
#export CODE_EXTENSIONSDIR=/opt/codeserverextensions
#export NOTEBOOK_SRC_SUBDIR=$NOTEBOOK_SRC_SUBDIR

echo "### ENV ###"
env
echo "### ENV ###"

jupyter lab --notebook-dir=/notebooks --ip 0.0.0.0 --no-browser
