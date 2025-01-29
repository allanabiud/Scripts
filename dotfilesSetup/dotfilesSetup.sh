#!/bin/bash
# shellcheck disable=2207,2010
# Author: Allan Nyagaka

# This script is for setting up dotfiles

################################################################################
######################## GLOBAL VARIABLES ######################################
################################################################################
# Global variables
export DOTFILES_DIR=""

################################################################################
########################### FUNCTIONS ##########################################
################################################################################

#################################
######### COLORS ###############
#################################
RED='\033[0;31m' # Red
# RED_BOLD='\033[1;31m' # Bold Red
GREEN='\033[0;32m' # Green
# GREEN_BOLD='\033[1;32m' # Bold Green
YELLOW='\033[0;33m' # Yellow
# YELLOW_BOLD='\033[1;33m' # Bold Yellow
BLUE='\033[0;34m' # Blue
# BLUE_BOLD='\033[1;34m' # Bold Blue
NC='\033[0m' # No Color

##################################
######### CONFIRMATION ##########
##################################
# Prompt user for confirmation
confirm() {
  echo
  while true; do
    echo -e -n "${YELLOW}$1 ([y]/n) ${GREEN}(Default: y): ${NC}"
    read -r choice
    case $choice in
    "" | y | Y) return 0 ;;
    n | N) return 1 ;;
    *) echo "Please answer Y/y, N/n or press Enter for yes." ;;
    esac
  done
}

##################################
######### CONTINUE ##############
##################################
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

##################################
######### PROMPT SUDO ###########
##################################
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

##################################
######### MESSAGES ##############
##################################
# Function to print colored messages
print_message() {
  echo -e "\n${BLUE}==> $1${NC}"
}
# Function to print success message
print_success() {
  echo -e "\n${GREEN}==> $1${NC}"
}
# Function to print error message
print_error() {
  echo -e "\n${RED}==> $1${NC}"
}
# Function to print warning message
print_warning() {
  echo -e "\n${YELLOW}==> $1${NC}"
}

# Function to print separator
print_separator() {
  echo -e "\n${BLUE}------------------------------------------------------------------------------${NC}"
}

# Function to print short large separator
print_short_large_separator() {
  echo -e "${BLUE}======================================${NC}"
}
# Function to print long large separator
print_long_large_separator() {
  echo -e "${BLUE}===============================================================================${NC}"
}

# Function to print welcome message
print_welcome_message() {
  print_long_large_separator
  echo -e "${BLUE}                       DOTFILES SETUP SCRIPT ${NC}"
  print_long_large_separator

  print_message "This is my dotfiles setup script."
  print_message "It is able to:"
  echo -e " ${YELLOW}- Install script dependencies"
  echo -e " ${YELLOW}- Clone dotfiles repositories"
  echo -e " ${YELLOW}- Stow dotfiles"
  echo -e " ${YELLOW}- Handle existing dotfiles"
  print_separator
  print_warning "${YELLOW}NOTE: ${BLUE}It is super-interactive and will ask for confirmation before proceeding."
}

# Print grant sudo access message
print_sudo_access_message() {
  print_short_large_separator
  echo -e "${BLUE}        Grant Root Access ${NC}"
  print_short_large_separator
}

# Print script dependencies message
print_script_dependencies_message() {
  print_short_large_separator
  echo -e "${BLUE}        Script Dependencies ${NC}"
  print_short_large_separator
}

# Print clone dotfiles repository message
print_clone_dotfiles_repository_message() {
  print_short_large_separator
  echo -e "${BLUE}  Section 1: Clone Dotfiles Repository ${NC}"
  print_short_large_separator
}

# Print stow dotfiles message
print_stow_dotfiles_message() {
  print_short_large_separator
  echo -e "${BLUE}  Section 2: Stow Dotfiles ${NC}"
  print_short_large_separator
}

# Print script completed message
print_script_completed_message() {
  print_long_large_separator
  echo -e "${BLUE}                  DOTFILES SETUP SCRIPT COMPLETED   ${NC}"
  print_long_large_separator
}

##################################
######### PRINT GRID ############
##################################
# Function to print items in a grid layout
print_grid() {
  # Usage: print_grid [options] [number of columns] "[list of items]"
  # Options:
  #   -n, --no-numbering: Disable numbering of items

  # Example: print_grid 2 "${dotfiles_list[@]}"
  # Example: print_grid -n 3 "${dotfiles_list[@]}"
  # Example: print_grid --no-numbering "${dotfiles_list[@]}" # Uses 2 columns by default and numbering is off

  local no_numbering=false
  local cols=2 # Defaults to 2 columns if not specified

  # Parse options
  while [[ "$1" == -* ]]; do
    case "$1" in
    -n | --no-numbering)
      no_numbering=true
      shift
      ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
    esac
  done

  # Check if the next argument is a number (column count)
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    cols="$1"
    shift
  fi

  local items=("$@")
  local total_items=${#items[@]}
  local rows=$(((total_items + cols - 1) / cols))
  local col_width=25 # Adjust this value to change the column width

  for ((i = 0; i < rows; i++)); do
    for ((j = 0; j < cols; j++)); do
      index=$((i + j * rows))
      if ((index < total_items)); then
        if $no_numbering; then
          printf "${YELLOW} - %-${col_width}s${NC}" "${items[index]}"
        else
          printf "${YELLOW}%2d - %-${col_width}s${NC}" $((index + 1)) "${items[index]}"
        fi
      fi
    done
    echo
  done
}

##################################
##### SCRIPT DEPENDENCIES #######
##################################
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

    print_separator

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

##################################
######### VALIDATION ############
##################################
# Function to validate Git URL
validate_git_url() {
  local url=$1
  # Basic regex to validate Git URLs
  local git_url_regex='^((https?://|git@|git://)([[:alnum:]_.-]+@)?[[:alnum:]_.-]+)(:|/)[[:alnum:]_.-]+/[[:alnum:]_.-]+(.git)?$'
  if [[ $url =~ $git_url_regex ]]; then
    return 0
  else
    return 1
  fi
}
# Function to validate directory path
validate_directory_path() {
  local path=$1
  # Empty tilde expansion to home directory
  path=${path/#\~/$HOME}
  # Check if path contains only allowed characters
  if [[ "$path" =~ ^[a-zA-Z0-9_/.-]+$ ]]; then
    return 0
  else
    return 1
  fi
}

##################################
######### CLONE DOTFILES #########
##################################
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

##################################
### HANDLE EXISTING DOTFILES #####
##################################
# Function to handle existing config files
handle_existing_dotfiles() {
  local file=$1
  local target_path="$HOME/.config/$file"

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    while true; do
      if [ -L "$target_path" ]; then
        local link_target
        link_target=$(readlink -f "$target_path")
        # Broken symlink
        if [ ! -e "$link_target" ]; then
          print_warning "File or directory $target_path is a broken symlink pointing to non-existent file or directory."
          echo -e "${YELLOW} 1) Delete the broken symlink and proceed"
          echo -e "${YELLOW} 2) Skip stowing this file"
          echo -e -n "${BLUE} Select an option: (1/2): ${NC}"
          read -r choice
          print_separator

          case $choice in
          1)
            if confirm "Are you sure you want to delete the broken symlink?"; then
              rm -rf "$target_path"
              print_success "Removed broken symlink $target_path"
              return 0
            else
              print_message "Skipping $target_path"
              return 1
            fi
            ;;
          2)
            print_message "Skipping $target_path"
            return 1
            ;;
          *)
            print_error "Invalid option. Please select an option from the list."
            continue
            ;;
          esac
        elif [[ "$link_target" == "$HOME/dotfiles/*" ]]; then
          # Symlinked to another package
          print_warning "File or directory $target_path is already stowed by another package in dotfiles repo."
          echo -e "${YELLOW} 1) Overwrite (unstow other package and stow this package)"
          echo -e "${YELLOW} 2) Skip stowing this file"
          echo -e -n "${BLUE} Select an option: (1/2): ${NC}"
          read -r choice
          case $choice in
          1)
            local stow_dir
            local package
            stow_dir=$(dirname "$(dirname "$link_target")")
            package=$(basename "$(dirname "$link_target")")
            if confirm "Are you sure you want to unstow $package?"; then
              stow -D -d "$stow_dir" "$package"
              print_success "Unstowed package $package"
              rm -rf "$target_path"
              print_success "Removed $target_path"
              return 0
            else
              print_message "Skipping $target_path"
              return 1
            fi
            ;;
          2)
            print_message "Skipping $target_path"
            return 1
            ;;
          *)
            print_error "Invalid option. Please select an option from the list."
            continue
            ;;
          esac
        else
          # Symlinked to location outside of stow packages in dotfiles repo
          print_warning "File or directory $target_path is already symlinked to $link_target."
          echo -e "${YELLOW} 1) Overwrite symlink"
          echo -e "${YELLOW} 2) Backup symlink and replace"
          echo -e "${YELLOW} 3) Skip stowing this file"
          echo -e -n "${BLUE} Select an option (1/2/3): ${NC}"
          read -r choice
          case $choice in
          1)
            if confirm "Are you sure you want to overwrite $target_path?"; then
              rm -rf "$target_path"
              print_success "Removed $target_path"
              return 0
            else
              print_message "Skipping $target_path"
              return 1
            fi
            ;;
          2)
            if confirm "Are you sure you want to backup $target_path?"; then
              mv "$target_path" "${target_path}.backup"
              print_success "Existing file or directory backed up as ${file}.backup"
              return 0
            else
              print_message "Skipping $target_path"
              return 1
            fi
            ;;
          3)
            print_message "Skipping $target_path"
            return 1
            ;;
          *)
            print_error "Invalid option. Please select an option from the list."
            continue
            ;;
          esac
        fi
      else
        # Regular file
        print_warning "File or directory $target_path already exists."
        echo -e "${YELLOW} 1) Overwrite"
        echo -e "${YELLOW} 2) Backup and replace"
        echo -e "${YELLOW} 3) Skip stowing this file"
        echo -e -n "${BLUE} Select an option (1/2/3): ${NC}"
        read -r choice
        case $choice in
        1)
          if confirm "Are you sure you want to overwrite $target_path?"; then
            rm -rf "$target_path"
            print_success "Removed $target_path"
            return 0
          else
            print_message "Skipping $target_path"
            return 1
          fi
          ;;
        2)
          if confirm "Are you sure you want to backup $target_path?"; then
            mv "$target_path" "${target_path}.backup"
            print_success "Existing file or directory backed up as ${file}.backup"
            return 0
          else
            print_message "Skipping $target_path"
            return 1
          fi
          ;;
        3)
          print_message "Skipping $target_path"
          return 1
          ;;
        *)
          print_error "Invalid option. Please select an option from the list."
          continue
          ;;
        esac
      fi
    done
  fi
  return 0
}

##################################
######### STOW DOTFILES ##########
##################################
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

##################################
######### SCRIPT COMPLETE ########
##################################
# Function to print script completed message and repeat the script
function script_completed {

  # Variable to repeat a section
  repeat_section=true

  # Loop to repeat a section if variable is true
  while $repeat_section; do

    # Check if we need to clear the screen
    if [ "$clear_screen" = true ]; then
      clear -x
    fi

    # Variable to clear the screen
    clear_screen=true

    # Call the print_script_completed_message function
    print_script_completed_message

    # Prompt user if they want to repeat a section or the entire script
    echo -e "${BLUE} Would you like to:"
    echo -e "${YELLOW} 1) Repeat the entire script."
    echo -e "${YELLOW} 2) Repeat cloning the dotfiles repository (Section 1)"
    echo -e "${YELLOW} 3) Repeat stowing dotfiles (Section 2)"
    echo -e "${YELLOW} 4) Exit"
    echo -e -n "${BLUE} Select an option (1/2/3/4): ${NC}"
    read -r final_choice

    case $final_choice in
    1)
      # Print message
      print_message "Repeating entire script....."
      # Variable to repeat a section if variable is true
      repeat_section=false
      # Clear the screen if variable is true
      clear_screen=true
      ;;
    2)
      # Clear the screen
      clear -x
      # Print message
      print_message "Repeating cloning dotfiles repository section....."
      # Call the print_clone_dotfiles_repository_message function
      print_clone_dotfiles_repository_message
      # Call the clone_dotfiles function
      clone_dotfiles
      # Continue with script
      continue_with_script
      # Clear the screen if variable is true
      clear_screen=true
      ;;
    3)
      # Clear the screen
      clear -x
      # Print message
      print_message "Repeating stowing dotfiles section....."
      # Call the print_stow_dotfiles_message function
      print_stow_dotfiles_message
      # Call the stow_dotfiles function
      stow_dotfiles
      # Continue with script
      continue_with_script
      # Clear the screen if variable is true
      clear_screen=true
      ;;
    4)
      print_separator
      # Print message
      print_message "Exiting script....."
      # Variable to repeat the entire script if variable is true

      # NOTE: Check later
      repeat_script=false

      # Variable to repeat a section if variable is true
      repeat_section=false
      # Clear the screen if variable is true
      clear_screen=false
      ;;
    *)
      # Print error message
      print_error "Invalid option. Please select an option from the list."
      # Clear the screen if variable is true
      clear_screen=false
      ;;
    esac
  done
}

################################################################################

########################### MAIN SCRIPT ########################################

################################################################################

# Variable to repeat the entire script
repeat_script=true

# Loop to repeat the entire script if variable is true
while $repeat_script; do

  ################################################################################
  # WELCOME MESSAGE
  ################################################################################

  # Clear the screen
  clear

  # Call the print_welcome_message function
  print_welcome_message

  # Continue with script
  continue_with_script

  ################################################################################
  # GRANT ROOT ACCESS
  ################################################################################

  # Clear the screen
  clear -x

  # Call the print_sudo_access_message function
  print_sudo_access_message

  # Call the prompt_sudo function
  prompt_sudo

  # Continue with script
  continue_with_script

  ################################################################################
  # SCRIPT DEPENDENCIES
  ################################################################################

  clear -x

  # Call the print_script_dependencies_message function
  print_script_dependencies_message

  # Install script dependencies
  script_dependencies

  # Continue with script
  continue_with_script

  ################################################################################
  # CLONE DOTFILES REPOSITORY
  ################################################################################

  clear -x

  # Call the print_clone_dotfiles_repository_message function
  print_clone_dotfiles_repository_message

  # Clone or update dotfiles repo
  clone_dotfiles

  # Continue with script
  continue_with_script

  ################################################################################
  # STOW DOTFILES
  ################################################################################

  clear -x

  # Call the print_stow_dotfiles_message function
  print_stow_dotfiles_message

  # Stow dotfiles
  stow_dotfiles

  # Continue with script
  continue_with_script

  ################################################################################
  # END OF SCRIPT SECTION
  ################################################################################

  clear -x

  # Call the script_completed function
  script_completed

done
