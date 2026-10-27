#!/bin/bash
set -euo pipefail

version=3.1.0
font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/PlemolJP_NF"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 3 \
    "https://github.com/yuru7/PlemolJP/releases/download/v${version}/PlemolJP_NF_v${version}.zip" \
    -o "$work_dir/plemoljp.zip"
unzip -q "$work_dir/plemoljp.zip" -d "$work_dir/fonts"
mkdir -p "$font_dir"
find "$work_dir/fonts" -type f -name '*.ttf' -exec install -m 644 {} "$font_dir/" \;
fc-cache -f "$font_dir"
