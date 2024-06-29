#!/bin/bash

function install_mise() {
    echo "Installing Mise..."
    curl https://mise.run | sh
}

command -v mise 1>/dev/null || install_mise
