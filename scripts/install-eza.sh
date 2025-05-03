#!/bin/bash

# システムアーキテクチャを検出
ARCH=$(uname -m)

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    # Raspberry Pi (aarch64/arm64)向けのバイナリをダウンロード
    wget -c https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz -O - | tar xz
else
    # デフォルト：x86_64向けのバイナリをダウンロード
    wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
fi

chmod +x eza
mv eza $HOME/.local/bin/eza
curl -OL https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza
mv _eza $HOME/.config/zsh/site-functions/_eza
