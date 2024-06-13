#!/bin/bash

wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
chmod +x eza
mv eza $HOME/.local/bin/eza
curl -OL https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza
mv _eza $HOME/.config/zsh/site-functions/_eza
