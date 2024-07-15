#!/bin/bash

if [ -d $HOME/.emacs.d ]; then
    echo "update spacemacs"
    cd $HOME/.emacs.d
    git pull --rebase
else
    echo "install spacemacs"
    git clone https://github.com/syl20bnr/spacemacs $HOME/.emacs.d
fi
