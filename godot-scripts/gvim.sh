#!/bin/bash
PIPE="$HOME/.cache/nvim/godot.pipe"

# Ensure the directory exists
mkdir -p "$(dirname "$PIPE")"

# Start nvim in project root, listening on the pipe
nvim --listen "$PIPE" .
