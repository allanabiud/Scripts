#!/bin/bash

# Print empty line
print_empty_line() {
  echo ""
}
# Function to update system
update_system() {
  gum spin --spinner dot --title "Updating system..." -- sudo pacman -Syu --noconfirm
  echo "System updated."
  print_empty_line
}

# Function to enable Color and ILoveCandy in pacman.conf
configure_pacman() {
  echo "Configuring pacman..."

  # Enable color if not already enabled
  sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

  # Add ILoveCandy if not already present
  sudo grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

  gum format -- "# Pacman configured to:" "- Use color" "- Show pacman eating the dots"
  print_empty_line
}

# # Function to install packages
# install_packages() {
#   echo "Installing packages: $@"
#   pacman -S --noconfirm "$@"
# }
