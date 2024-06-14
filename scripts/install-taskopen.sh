#!/bin/bash

rm -rf /tmp/taskopen
cd /tmp
git clone https://github.com/jschlatow/taskopen.git
cd taskopen
make PREFIX=$HOME/.local
make PREFIX=$HOME/.local install
cd /tmp
rm -rf /tmp/taskopen
