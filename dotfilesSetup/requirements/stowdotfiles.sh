#!/bin/bash
# shellcheck disable=2207,2010,1091

# Source other functions
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh
source ./requirements/printgrid.sh
source ./requirements/handleexistingdotfiles.sh

################################################################################

# Function to stow a specific dotfile
stow_dotfiles() {
  local dotfiles_dir="$DOTFILES_DIR"
  local dotfiles_list=()

  # Check if DOTFILES_DIR is set
  if [ -z "$DOTFILES_DIR" ]; then
    print_error "DOTFILES_DIR is not set. Did you clone the dotfiles repo first?"
    return 1
  fi

  # List all dotfiles in cloned repo
  print_message "Checking for dotfiles in cloned repo ($dotfiles_dir):"
  print_separator
  print_message "Dotfiles in cloned repo ($YELLOW$dotfiles_dir$BLUE):"
  dotfiles_list=($(ls -1 "$dotfiles_dir" | grep -v -E '\.(md|git)$'))
  print_grid "${dotfiles_list[@]}"

  # Prompt user to select dotfiles to stow
  echo -e -n "\n${BLUE} Select dotfile(s) to stow (space-separated numbers, or 'a' for all): ${NC}"
  read -r selection
  print_separator

  # Get stow selection
  local selected_dotfiles=()
  if [ "$selection" = "a" ]; then
    selected_dotfiles=("${dotfiles_list[@]}")
  else
    for num in $selection; do
      if ((num >= 1 && num <= ${#dotfiles_list[@]})); then
        selected_dotfiles+=("${dotfiles_list[$((num - 1))]}")
      else
        print_error "Invalid selection: $num"
        return 1
      fi
    done
  fi

  # List and confirm stow selection
  echo -e "\n${BLUE}You have selected the following dotfiles to stow:${NC}"
  for ((i = 0; i < ${#selected_dotfiles[@]}; i++)); do
    echo -e "${YELLOW} - ${selected_dotfiles[$i]}${NC}"
  done
  if confirm "Is this correct?"; then
    print_separator
    print_message "Stowing selected dotfiles.."
  else
    print_separator
    print_message "Please reselect dotfiles to stow"
    stow_dotfiles
    return 1
  fi

  # Navigate to cloned repo to avoid stow slash errors
  cd "$dotfiles_dir" || {
    print_error "Failed to navigate to $dotfiles_dir"
    exit 1
  }

  # Stow selected dotfiles
  if [ "$selection" = "a" ]; then
    for dotfile in "${dotfiles_list[@]}"; do
      print_message "Stowing $dotfile"
      if handle_existing_dotfiles "$dotfile"; then
        if stow "$dotfile" -v -R -t "$HOME"; then
          print_success "Stowed $dotfile successfully"
        else
          print_error "Failed to stow $dotfile"
        fi
      else
        print_message "Skipping $dotfile"
      fi
    done
  else
    for num in $selection; do
      if ((num >= 1 && num <= ${#dotfiles_list[@]})); then
        dotfile=${dotfiles_list[$((num - 1))]}
        print_separator
        print_message "Stowing $dotfile"
        if handle_existing_dotfiles "$dotfile"; then
          if stow "$dotfile" -v -R -t "$HOME"; then
            print_success "Stowed $dotfile successfully"
          else
            print_error "Failed to stow $dotfile"
          fi
        else
          print_message "Skipping $dotfile"
        fi
      else
        print_error "Invalid selection: $num"
      fi
    done
  fi
}
