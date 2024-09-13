#!/bin/bash
# This script is for setting up dotfiles
# Author: Allan Nyagaka

## Source other functions
# Check if globalvariables.sh exists
source ./requirements/globalvariables.sh
source ./requirements/messages.sh
source ./requirements/continue.sh
source ./requirements/promptsudo.sh
source ./requirements/scriptdependencies.sh
source ./requirements/clonerepository.sh
source ./requirements/stowdotfiles.sh
source ./requirements/scriptcomplete.sh

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
