#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh

################################################################################

# Function to continue with script function
continue_with_script() {
  print_separator
  if confirm "Continue?"; then
    print_message "Continuing......"
  else
    print_message "Exiting......"
    print_separator
    exit 1
  fi
  print_separator
}
