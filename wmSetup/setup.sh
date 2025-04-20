#!/bin/bash

# Ensure Gum is installed
if ! command -v gum &>/dev/null; then
  echo "Gum is not installed. Please install it first."
  exit 1
fi

# # Ensure script is running as root
# if [[ $EUID -ne 0 ]]; then
#   echo "Please run this script as root."
#   exit 1
# fi

# Display title
clear
gum style --border double --margin "1" --padding "1" --border-foreground 212 "Arch Linux Setup Script"

# Load common functions
source ./modules/common.sh

# Update system
update_system

# Configure pacman
configure_pacman

# Interactive selection using Gum
WM=$(gum choose --header "Choose window manager:" "Hyprland" "Sway (Coming Soon)" "i3 (Coming Soon)")

case $WM in
"Hyprland")
  source ./modules/hyprland.sh
  setup_hyprland
  ;;
"Sway (Coming Soon)")
  echo "Sway setup is not yet implemented."
  ;;
"i3 (Coming Soon)")
  echo "i3 setup is not yet implemented."
  ;;
esac
