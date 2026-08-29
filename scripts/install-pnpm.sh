#!/bin/bash

function install() {
    echo "install pnpm"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
}

function upgrade() {
    pnpm self-update
}

command -v pnpm 1>/dev/null || install
upgrade
