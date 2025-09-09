#!/bin/bash
PIPE="$HOME/.cache/nvim/godot.pipe"

if [ -n "$1" ]; then
  file="$1"
  nvim --server "$PIPE" --remote-send ":e ${file}<CR>"
fi
