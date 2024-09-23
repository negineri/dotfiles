#!/bin/bash

if [ ! -d $HOME/org-roam ]; then
    echo "clone org-roam"
    git clone git@github.com:negineri/roam.git $HOME/org-roam
fi
