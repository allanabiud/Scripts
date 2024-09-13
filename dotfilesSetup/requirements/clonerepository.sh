#!/bin/bash
# shellcheck disable=1091,2034

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh
source ./requirements/validation.sh
source ./requirements/globalvariables.sh

################################################################################

# Function to clone my dotfiles repo
clone_dotfiles() {
  local default_repo_url="https://github.com/abiud254/dotfiles.git"
  local default_target_dir="$HOME/dotfiles"
  local repo_url
  local target_dir
  local clone_success=false

  # Prompt user for repo URL
  while true; do
    print_message "${BLUE}Acceptable URL Syntax: ${NC}"
    echo -e " ${BLUE}HTTPS URL:${NC} ${YELLOW}https://github.com/username/repository.git${NC}"
    echo -e " ${BLUE}SSH URL:${NC} ${YELLOW}git@github.com:username/repository.git${NC}"
    echo
    echo -e -n "${BLUE} Enter the repository URL ${NC}${GREEN}(Default: $default_repo_url): ${NC}"
    read -r user_repo_url
    repo_url=${user_repo_url:-$default_repo_url}
    if validate_git_url "$repo_url"; then
      break
    else
      print_error "Invalid Git URL. Please enter a valid Git URL."
    fi
  done

  print_separator

  # Prompt user for target directory
  while true; do
    print_message "${BLUE}Acceptable Directory Syntax: ${NC}"
    echo -e " ${BLUE}Absolute path:${NC} ${YELLOW}/home/username/dotfiles${NC}"
    echo -e " ${BLUE}Relative path:${NC} ${YELLOW}~/dotfiles${NC}"
    echo
    echo -e -n "${BLUE} Enter the target directory ${NC}${GREEN}(Default: $default_target_dir): ${NC}"
    read -r user_target_dir
    target_dir=${user_target_dir:-$default_target_dir}
    if validate_directory_path "$target_dir"; then
      break
    else
      print_error "Invalid directory path. Please enter a valid directory path."
    fi
  done

  # Expand tilde in target_dir
  target_dir=${target_dir/#\~/$HOME}

  print_separator
  print_message "Cloning $YELLOW$repo_url$BLUE to $YELLOW$target_dir$BLUE.."
  print_separator
  while [ $clone_success = false ]; do
    if [ -d "$target_dir" ]; then
      print_message "Directory $target_dir already exists."
      echo -e "${YELLOW} 1) Delete existing repo and clone again"
      echo -e "${YELLOW} 2) Try updating the existing repo"
      echo -e "${YELLOW} 3) Use existing repo without updating"
      echo -e "${YELLOW} 4) Exit"
      echo -e -n "${BLUE} Select an option (1/2/3/4): ${NC}"
      read -r choice
      print_separator

      case $choice in
      1)
        if confirm "Are you sure you want to delete the existing repo?"; then
          rm -rf "$target_dir"
          print_success "Dotfiles repository deleted"
          if confirm "Do you want to clone $repo_url to $target_dir?"; then
            print_message "Cloning dotfiles repository.."
            if git clone "$repo_url" "$target_dir"; then
              print_success "Dotfiles repository cloned successfully"
              clone_success=true
            else
              print_error "Failed to clone dotfiles repository"
              if ! confirm "Do you want to retry cloning the repo?"; then
                print_warning "Dotfiles repository not cloned. Exiting.."
                exit 1
              fi
            fi
          else
            print_warning "Dotfiles repository not cloned. Exiting.."
            exit 1
          fi
        else
          print_message "Existing repo not deleted. Choose another option."
        fi
        ;;
      2)
        print_message "Attempting to update existing dotfiles repository.."
        if cd "$target_dir" && git remote set-url origin "$repo_url" && git pull; then
          print_success "Dotfiles repository updated"
          clone_success=true
        else
          print_error "Failed to update dotfiles repository"
          if ! confirm "Do you want to retry updating the repo?"; then
            print_warning "Dotfiles repository not updated. Exiting.."
            exit 1
          fi
        fi
        ;;
      3)
        print_message "Using existing dotfiles repository.."
        clone_success=true
        ;;
      4)
        print_warning "Dotfiles repository not cloned. Exiting.."
        exit 1
        ;;
      *)
        print_error "Invalid option. Please select an option from the list."
        ;;
      esac
    else
      if confirm "Do you want to clone $repo_url to $target_dir?"; then
        print_message "Cloning dotfiles repository.."
        if git clone "$repo_url" "$target_dir"; then
          print_success "Dotfiles repository cloned successfully"
          clone_success=true
        else
          print_error "Failed to clone dotfiles repository"
          if ! confirm "Do you want to retry cloning the repo?"; then
            print_warning "Dotfiles repository not cloned. Exiting.."
            exit 1
          fi
        fi
      else
        print_warning "Dotfiles repository not cloned. Exiting.."
        exit 1
      fi
    fi
  done
  # Return target directory to be used in other functions
  DOTFILES_DIR="$target_dir"
}
