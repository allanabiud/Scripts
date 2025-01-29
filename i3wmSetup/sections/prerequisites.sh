#!/bin/bash
# This is the dependencies section of the i3wmSetup script.
# It installs the necessary dependencies for the script to run.

################################################################################
########################### FUNCTIONS ##########################################
################################################################################

#######################
####### COLORS #######
#######################
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
# Continue with section function
continue_with_section() {
	echo -e -n "\n${BLUE}----------------------------------------${NC}"
	if confirm "Continue section?"; then
		print_message "Continuing......"
	else
		print_message "Exiting......"
		echo -e "${BLUE}----------------------------------------${NC}"
		exit 1
	fi
	echo -e "${BLUE}----------------------------------------${NC}"
}
# Continue with script function
continue_with_script() {
	echo -e -n "\n${BLUE}----------------------------------------${NC}"
	if confirm "Continue script?"; then
		print_message "Continuing......"
	else
		print_message "Exiting......"
		echo -e "${BLUE}----------------------------------------${NC}"
		exit 1
	fi
	echo -e "${BLUE}----------------------------------------${NC}"
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
######### PROMPT SUDO ###########
##################################
# Prompt for sudo access with confirmation
prompt_sudo() {
	print_warning "SUDO PRIVILEGES REQUIRED"
	print_message "This script requires sudo access to:"
	echo -e "${YELLOW} - Install script and i3wm dependencies"
	echo -e "${YELLOW} - Install yay AUR Helper"
	echo -e "${YELLOW} - Install applications"
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
######### UPDATE SYSTEM #########
##################################
# Function to update system
update_system() {
	if confirm "Do you want to run a system update?"; then
		local max_retries=3
		local retry_count=0

		while [ $retry_count -lt $max_retries ]; do
			print_message "Updating your system.."
			if sudo pacman -Syu --noconfirm; then
				print_success "System updated"
				return 0
			else
				print_error "System update failed"
				if [ $retry_count -lt $(($max_retries - 1)) ]; then
					if confirm "Do you want to retry the update?"; then
						((retry_count++))
					else
						print_message "Skipping system update"
						return 0
					fi
				else
					print_error " Maximum retries reached."
					if confirm "Do you want to skip the update?"; then
						print_message "Skipping system update.."
						return 0
					else
						print_message "Retrying system update.."
					fi
				fi
			fi
		done
	else
		print_message "Skipping system update"
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
# Function to print section message
print_section_message() {
	print_long_large_separator
	echo -e "${BLUE}   Section 1: Install system and script prerequisites ${NC}"
	print_long_large_separator

	print_message "This section will:"
	echo -e " ${YELLOW}- Create home directories"
	echo -e " ${YELLOW}- Install yay AUR helper"
	echo -e " ${YELLOW}- Install i3 dependencies"
	echo -e " ${YELLOW}- Install system packages"
	echo -e " ${YELLOW}- Install terminal prerequisites"
	print_separator
}
# Print section complete message
print_section_complete_message() {
	print_long_large_separator
	echo -e "${GREEN}        Section Complete ${NC}"
	print_long_large_separator
}

# Print grant sudo access message
print_sudo_access_message() {
	print_short_large_separator
	echo -e "${BLUE}        Grant Root Access ${NC}"
	print_short_large_separator
}

# Print create home directories message
print_create_home_directories_message() {
	print_short_large_separator
	echo -e "${BLUE} 1.1 Create home directories ${NC}"
	print_short_large_separator
}

# Print install yay message
print_install_yay_message() {
	print_short_large_separator
	echo -e "${BLUE} 1.2 Install yay AUR helper ${NC}"
	print_short_large_separator
}

# Print install i3 dependencies message
print_install_i3_dependencies_message() {
	print_short_large_separator
	echo -e "${BLUE} 1.3 Install i3 dependencies ${NC}"
	print_short_large_separator
}

# Print install system packages message
print_install_system_packages_message() {
	print_short_large_separator
	echo -e "${BLUE} 1.4 Install system packages ${NC}"
	print_short_large_separator
}

# Print install terminal prerequisites message
print_install_terminal_prerequisites_message() {
	print_short_large_separator
	echo -e "${BLUE} 1.5 Install terminal prerequisites ${NC}"
	print_short_large_separator
}

# Print script completed message
print_script_completed_message() {
	print_long_large_separator
	echo -e "${BLUE}              SECTION 1 OF THE SCRIPT COMPLETED   ${NC}"
	print_long_large_separator
}

##################################
######## CREATE HOME DIRS ########
##################################
# Create home directories if they don't exist
create_home_directories() {

	# List of home directories to check
	home_dirs=("$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Music" "$HOME/Pictures" "$HOME/Videos")

	# Initialize a flag to track missing directories
	missing_dirs=()

	print_message "Checking if home directories exist.."
	# Loop through directories to check if any are missing
	for dir in "${home_dirs[@]}"; do
		if [ ! -d "$dir" ]; then
			missing_dirs+=("$(basename "$dir")")
			break
		fi
	done

	# If any directory is missing
	if [ ${#missing_dirs[@]} -ne 0 ]; then
		print_message "The following home directories do not exist."
		print_grid "${missing_dirs[@]}"

		if confirm "Create them?"; then
			print_message "Creating home directories.."
			mkdir -p "${home_dirs[@]}"
			print_success "Home directories created successfully"
		else
			print_warning "Home directories are required for this script. Exiting."
			exit 1
		fi
	else
		print_success "All home directories already exist"
	fi
}

##################################
######### INSTALL YAY ###########
##################################

# Function to install yay
yay_install() {
	local dependencies=("yay")
	local to_install=()
	local retry=true

	while $retry; do
		print_message "Package required:"
		for dependency in "${dependencies[@]}"; do
			echo -e "${YELLOW} - $dependency${NC}"
		done
		echo

		print_message "Checking if $dependency is installed...."
		for dependency in "${dependencies[@]}"; do
			if ! pacman -Qi $dependency &>/dev/null; then
				to_install+=($dependency)
			fi
		done

		if [ ${#to_install[@]} -eq 0 ]; then
			print_success "yay is already installed"
			retry=false
		else
			print_message "The following package needs to be installed:"
			for dependency in "${to_install[@]}"; do
				echo -e "${YELLOW} - $dependency${NC}"
			done

			if confirm "Do you want to install yay?"; then
				print_message "Installing yay.."
				if sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git "$HOME/Documents" && cd "$HOME/Documents/yay-bin" && makepkg -si --noconfirm; then
					print_success "yay installed successfully"
					retry=false
				else
					print_error "Failed to install yay AUR Helper"
					if confirm "Do you want to retry the installation?"; then
						retry=true
					else
						print_warning "yay is required for the application part of this script."
						print_error "Exiting.."
						exit 1
					fi
				fi
			else
				print_warning "yay is required for the application part of this script."
				if confirm "Do you want to continue without yay?"; then
					print_message "Continuing without yay.."
				else
					print_error "Exiting.."
					exit 1
				fi
			fi
		fi
	done
}

##################################
####### INSTALL I3 DEPS #########
##################################

# Function to check and install i3 dependencies
i3_dependencies() {
	local dependencies=("i3lock" "i3status" "i3blocks" "dmenu")
	local to_install=()
	local retry=true

	while $retry; do
		print_message "i3 dependencies to be installed:"
		for dependency in "${dependencies[@]}"; do
			echo -e "${YELLOW} - $dependency${NC}"
		done
		echo

		print_message "Checking if dependencies are installed...."
		for dependency in "${dependencies[@]}"; do
			if ! pacman -Qi $dependency &>/dev/null; then
				to_install+=($dependency)
			fi
		done

		if [ ${#to_install[@]} -eq 0 ]; then
			print_success "All i3 dependencies are already installed"
			retry=false
		else
			print_message "The following missing i3 dependencies need to be installed:"
			for dependency in "${to_install[@]}"; do
				echo -e "${YELLOW} - $dependency${NC}"
			done

			if confirm "Do you want to install these dependencies?"; then
				print_message "Installing i3 dependencies.."
				if sudo pacman -S --noconfirm "${to_install[@]}"; then
					print_success "i3 dependencies installed successfully"
					retry=false
				else
					print_error "Failed to install i3 dependencies"
					if confirm "Do you want to retry the installation?"; then
						retry=true
					else
						print_warning "i3 dependencies are required for this i3wm. Exiting."
						exit 1
					fi
				fi
			else
				print_long_large_separator
				print_warning "i3 dependencies are required for this i3wm."
				print_error "Exiting.."
				print_long_large_separator
				exit 1
			fi
		fi
	done
}

##################################
##### INSTALL SYSTEM DEPS #######
##################################

# Function to install script dependencies
system_prerequisites() {
	local dependencies=("tlp" "thermald" "nano" "vim" "bluez" "bluez-utils" "blueman" "nodejs" "npm" "jdk-openjdk" "cargo" "p7zip" "unrar" "tar" "rsync" "exfat-utils" "fuse-exfat" "ntfs-3g" "flac" "jasper" "aria2" "curl" "wget" "xss-lock" "nitrogen" "picom" "dunst" "pavucontrol" "xclip" "ttf-meslo-nerd" "ttf-font-awesome" "ttf-ms-fonts" "j4-dmenu-desktop" "lxappearance" "gnome-keyring" "android-tools" "arandr" "xorg-xrandr" "timeshift" "intel-ucode" "libva-utils")
	local to_install=()
	local retry=true

	while $retry; do
		print_message "System prerequisites required:"
		print_grid -n 5 "${dependencies[@]}"
		echo

		print_message "Checking if prerequisites are installed...."
		for dependency in "${dependencies[@]}"; do
			if ! yay -Qi $dependency &>/dev/null; then
				to_install+=($dependency)
			fi
		done

		if [ ${#to_install[@]} -eq 0 ]; then
			print_success "All system prerequisites are already installed"
			retry=false
		else
			print_message "The following missing system prerequisites need to be installed:"
			print_grid -n 5 "${to_install[@]}"
			if confirm "Do you want to install these prerequisites?"; then
				print_message "Installing system prerequisites.."
				if yay -S --noconfirm "${to_install[@]}"; then
					print_success "System prerequisites installed successfully"
					retry=false
				else
					print_error "Failed to install system prerequisites"
					if confirm "Do you want to retry the installation?"; then
						retry=true
					else
						print_warning "System prerequisites are required for this script. Exiting.."
						exit 1
					fi
				fi
			else
				print_long_large_separator
				print_warning "System prerequisites are required for this script."
				print_error "Exiting.."
				print_long_large_separator
				exit 1
			fi
		fi
	done
}

##################################
##### INSTALL TERMINAL DEPS #####
##################################

# Function to setup terminal
terminal_setup() {
	local dependencies=("alacritty" "starship" "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting")
	local to_install=()
	local retry=true

	while $retry; do
		print_message "Terminal dependencies to be installed:"
		print_grid -n 3 "${dependencies[@]}"
		echo

		print_message "Checking if terminal dependencies are installed...."
		for dependency in "${dependencies[@]}"; do
			if ! pacman -Qi $dependency &>/dev/null; then
				to_install+=($dependency)
			fi
		done
		if [ ${#to_install[@]} -eq 0 ]; then
			print_success "All terminal dependencies are already installed"
			retry=false
		else
			print_message "The following missing terminal dependencies need to be installed:"
			print_grid -n 3 "${to_install[@]}"
			if confirm "Do you want to install these dependencies?"; then
				print_message "Installing terminal dependencies.."
				if sudo pacman -S --noconfirm "${to_install[@]}"; then
					print_success "Terminal dependencies installed successfully"
					retry=false
				else
					print_error "Failed to install terminal dependencies"
					if confirm "Do you want to retry the installation?"; then
						retry=true
					else
						if confirm "Do you want to continue without terminal dependencies?"; then
							print_message "Continuing without terminal dependencies.."
						else
							print_error "Exiting.."
							exit 1
						fi
					fi
				fi
			else
				if confirm "Do you want to continue without terminal dependencies?"; then
					print_message "Continuing without terminal dependencies.."
				else
					print_error "Exiting.."
					exit 1
				fi
			fi
		fi
	done
}

################################################################################

####################### MAIN SCRIPT SECTION ####################################

################################################################################

##################################
# SECTION 1 WELCOME MESSAGE
##################################

# Clear the screen
clear

# Call the print section message function
print_section_message

# Continue with section
continue_with_section

#################################
# 1.1 Create home directories
#################################

# Clear the screen
clear -x

# Print 1.1 create home directories message
print_create_home_directories_message

# Call the create home directories function
create_home_directories

# Continue with section
continue_with_section

#################################
# 1.2 Install yay AUR helper
#################################

# Clear the screen
clear -x

# Print 1.2 install yay message
print_install_yay_message

# Call the yay install function
yay_install

# Continue with section
continue_with_section

#################################
# 1.3 Install i3 dependencies
#################################

# Clear the screen
clear -x

# Print 1.3 install i3 dependencies message
print_install_i3_dependencies_message

# Call the i3 dependencies function
i3_dependencies

# Continue with section
continue_with_section

#################################
# 1.4 Install system packages
#################################

# Clear the screen
clear -x

# Print 1.4 install system packages message
print_install_system_packages_message

# Call the system prerequisites function
system_prerequisites

# Continue with section
continue_with_section

#################################
# 1.5 Install terminal prerequisites
#################################

# Clear the screen
clear -x

# Print 1.5 install terminal prerequisites message
print_install_terminal_prerequisites_message

# Call the terminal setup function
terminal_setup

##################################
######## SECTION 2 COMPLETE ########
##################################

# Print section complete message
print_section_complete_message
