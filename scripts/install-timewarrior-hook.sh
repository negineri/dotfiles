#!/bin/bash

echo install timewarrior hook
if [ -f /opt/homebrew/share/doc/timew/ext/on-modify.timewarrior ]; then
  mkdir -p $HOME/.task/hooks
  cp /opt/homebrew/share/doc/timew/ext/on-modify.timewarrior $HOME/.task/hooks/
  chmod +x $HOME/.task/hooks/on-modify.timewarrior
else
  echo "File not found"
  exit 1
fi
