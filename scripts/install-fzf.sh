#!/bin/bash

if [ -d $HOME/.local/fzf ]; then
    echo "update fzf"
    cd $HOME/.local/fzf
    git pull
    ./install --bin
else
    echo "install fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.local/fzf
    $HOME/.local/fzf/install --bin
fi
