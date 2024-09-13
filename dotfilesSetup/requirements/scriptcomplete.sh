#!/bin/bash
# shellcheck disable=1091

# Source other functions
source ./requirements/colors.sh
source ./requirements/messages.sh

################################################################################

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
