#!/bin/bash

if [ -d $HOME/.local/transcrypt ]; then
    echo "update transcrypt"
    cd $HOME/.local/transcrypt
    git pull
else
    echo "install transcrypt"
    git clone --depth 1 https://github.com/elasticdog/transcrypt.git $HOME/.local/transcrypt
    ln -s $HOME/.local/transcrypt/transcrypt $HOME/.local/bin/transcrypt
fi
