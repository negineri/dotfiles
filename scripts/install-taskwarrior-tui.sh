#!/bin/bash

cd /tmp
curl https://github.com/kdheepak/taskwarrior-tui/releases/latest/download/taskwarrior-tui-x86_64-unknown-linux-musl.tar.gz -Lo - | tar xz
mkdir -p $HOME/.local/bin
mv taskwarrior-tui $HOME/.local/bin/
