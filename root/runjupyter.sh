#!/usr/bin/with-contenv /bin/zsh  
. $HOME/.zshrc

echo "### ENV ###"
env
echo "### ENV ###"

jupyter lab --notebook-dir=/notebooks --ip 0.0.0.0 --no-browser
