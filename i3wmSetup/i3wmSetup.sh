#!/bin/bash
# shellcheck disable=3054,3043,3030,2206,3024,3037,3010,3045,2086,3020,2004

# This is my i3 setup script for Arch Linux
# It is meant to be run once after installation of i3 using the archinstall script
# This script will install dependencies, my dotfiles and applications I use

# source ./sections/applications.sh
source ./sections/prerequisites.sh
source ./sections/configurations.sh

#######################
####### COLORS #######
#######################
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

#######################
####### FUNCTIONS #####
#######################
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

# Continue with script function
continue_with_script() {
  echo -e -n "\n${BLUE}----------------------------------------${NC}"
  if confirm "Continue?"; then
    print_message "Continuing......"
  else
    print_message "Exiting......"
    echo -e "${BLUE}----------------------------------------${NC}"
    exit 1
  fi
  echo -e "${BLUE}----------------------------------------${NC}"
}

# Function to print welcome message
print_welcome_message() {
  print_long_large_separator
  echo -e "${BLUE}                  i3WM SETUP SCRIPT FOR ARCH LINUX ${NC}"
  print_long_large_separator

  print_message "This is my i3 setup script for Arch Linux"
  print_message "It is meant to be run once after installation of i3 using the archinstall script"
  print_message "This script is divided into 3 sections:"
  echo -e "${YELLOW} - Installing system prerequisites"
  echo -e "${YELLOW} - Configuring the system"
  echo -e "${YELLOW} - Installing user applications"
  print_separator
  print_warning "${YELLOW}NOTE: ${BLUE}It is super-interactive and will ask for confirmation before proceeding."
}

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 1: Grant Root Access ${NC}"
echo -e "${BLUE}========================================${NC}"
# Call the prompt_sudo function
prompt_sudo

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 2: Update System ${NC}"
echo -e "${BLUE}========================================${NC}"
# Update system
update_system

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 3: Dependencies ${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${BLUE}******************************${NC}"
echo -e "${BLUE}  Part 1: Script Dependencies ${NC}"
echo -e "${BLUE}******************************${NC}"
# Install script dependencies
script_dependencies

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}******************************${NC}"
echo -e "${BLUE}  Part 2: Install yay ${NC}"
echo -e "${BLUE}******************************${NC}"
# Install yay
yay_install

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}******************************${NC}"
echo -e "${BLUE}  Part 3: i3 Dependencies ${NC}"
echo -e "${BLUE}******************************${NC}"
# Install i3 dependencies
i3_dependencies

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 4: Terminal Setup ${NC}"
echo -e "${BLUE}========================================${NC}"
# Setup terminal
terminal_setup

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 5: Setup Dotfiles ${NC}"
echo -e "${BLUE}========================================${NC}"
# Setup dotfiles
setup_dotfiles

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}----------------------------------------${NC}"
echo -e "${BLUE}    DOTFILES SETUP SCRIPT COMPLETED      ${NC}"
echo -e "${BLUE}    CONTINUE WITH I3 SETUP SCRIPT?              ${NC}"
echo -e "${BLUE}----------------------------------------${NC}"

# Continue with script
continue_with_script

clear -x
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Section 6: Applications ${NC}"
echo -e "${BLUE}========================================${NC}"
# Setup i3wm environment applications
i3wm_applications

# Continue with script
continue_with_script

clear -x
# SCRIPT COMPLETED
echo -e "\n${BLUE}================================================================================${NC}"
echo -e "${BLUE}                  I3 SETUP SCRIPT COMPLETED   ${NC}"
echo -e "${BLUE}================================================================================${NC}"

################################################################################
########################### MAIN SCRIPT ########################################
################################################################################
