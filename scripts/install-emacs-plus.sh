#!/bin/bash

if ! command -v emacs >/dev/null; then
    echo "install emacs-plus"
    brew tap d12frosted/emacs-plus
    brew install -q emacs-plus@29 --with-spacemacs-icon --with-native-comp
    osascript -e 'tell application "Finder" to make alias file to posix file "/opt/homebrew/opt/emacs-plus@29/Emacs.app" at POSIX file "/Applications" with properties {name:"Emacs.app"}'
    # brew services start d12frosted/emacs-plus/emacs-plus@29
fi
