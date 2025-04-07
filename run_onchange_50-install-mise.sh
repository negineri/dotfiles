#!/bin/bash

# 4月開始 2ヶ月に更新 12月と1月は同じ
# {{ mod ( div ( now | date "01" | int64 | add 4 ) 2 ) 6 }}

function install_mise() {
    echo "Installing Mise..."
    curl https://mise.run | sh
}

function update_mise() {
    echo "Updating Mise..."
    mise self-update
}

command -v mise 1>/dev/null || install_mise
update_mise
