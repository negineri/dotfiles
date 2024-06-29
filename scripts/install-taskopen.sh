#!/bin/bash

cd /tmp
wget -c https://github.com/negineri/taskopen/releases/latest/download/taskopen-linux-amd64 -O - | tar xz
cd taskopen
PREFIX=$HOME/.local
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/share/man/man1
mkdir -p $PREFIX/share/man/man5
install -m 0755 bin/taskopen $PREFIX/bin/taskopen
install -m 0644 share/man/taskopen.1.gz $PREFIX/share/man/man1/taskopen.1.gz
install -m 0644 share/man/taskopenrc.5.gz $PREFIX/share/man/man5/taskopenrc.5.gz
mkdir -p $PREFIX/share/taskopen/scripts/
cp -r share/taskopen/scripts/* $PREFIX/share/taskopen/scripts/
chmod -R 755 $PREFIX/share/taskopen/scripts
mkdir -p $PREFIX/share/taskopen/examples
cp -r share/taskopen/examples/* $PREFIX/share/taskopen/examples
chmod -R 755 $PREFIX/share/taskopen/examples

cd /tmp
rm -rf taskopen
