#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh

################################################################################

# Function to install script dependencies
script_dependencies() {
  local dependencies=("stow" "git")
  local to_install=()
  local retry=true

  while $retry; do
    print_message "Script dependencies required:"
    for dependency in "${dependencies[@]}"; do
      echo -e "${YELLOW} - $dependency${NC}"
    done
    echo

    print_message "Checking if dependencies are installed...."
    for dependency in "${dependencies[@]}"; do
      if ! pacman -Qi "$dependency" &>/dev/null; then
        to_install+=("$dependency")
      fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
      print_success "All script dependencies are already installed"
      retry=false
    else
      print_message "The following script dependencies are missing and need to be installed:"
      for dependency in "${to_install[@]}"; do
        echo -e "${YELLOW} - $dependency${NC}"
      done

      if confirm "Do you want to install these dependencies?"; then
        print_message "Installing script dependencies.."
        if sudo pacman -S --noconfirm "${to_install[@]}"; then
          print_success "Script dependencies installed successfully"
          retry=false
        else
          print_error "Failed to install script dependencies"
          if confirm "Do you want to retry the installation?"; then
            retry=true
          else
            print_warning "Script dependencies are required for this script. Exiting.."
            exit 1
          fi
        fi
      else
        print_warning "Script dependencies are required for this script. Exiting."
        exit 1
      fi
    fi
  done
}
