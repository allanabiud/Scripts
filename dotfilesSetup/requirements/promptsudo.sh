#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh

################################################################################

# Prompt for sudo access with confirmation
prompt_sudo() {
  print_warning "SUDO PRIVILEGES REQUIRED!!"
  print_separator
  print_message "This script requires sudo access to:"
  echo -e "${YELLOW} - Install script dependencies"
  print_separator
  if confirm "Do you want to grant sudo access?"; then
    # Clear any existing sudo credentials
    sudo -k
    # Attempt to get sudo access
    if sudo -v; then
      print_success "Root access granted"
      #Keep sudo privileges alive
      sudo -v
      while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
      done 2>/dev/null &
    else
      print_error "Failed to get sudo access. Exiting."
      exit 1
    fi
  else
    print_error "Root access denied. Exiting."
    exit 1
  fi
}
