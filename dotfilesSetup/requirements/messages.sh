#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh

################################################################################

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

# PRINT WELCOME MESSAGE
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
