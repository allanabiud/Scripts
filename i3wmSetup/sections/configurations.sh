#!/bin/bash

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

# Function to print items in a grid layout
print_grid() {
  local items=("$@")
  local cols=4
  local rows=$(((${#items[@]} + cols - 1) / cols))
  local col_width=25 # Adjust this value to change the column width

  for ((i = 0; i < rows; i++)); do
    for ((j = 0; j < cols; j++)); do
      index=$((i + j * rows))
      if [ $index -lt ${#items[@]} ]; then
        printf "${YELLOW} - %-${col_width}s${NC}" "${items[$index]}"
      fi
    done
    echo
  done
}

# Continue with script function
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

# Configure pacman
pacman_conf() {
  conf_file="/etc/pacman.conf"

  print_message "Configuring pacman to:"
  echo -e "${YELLOW} - Use color${NC}"
  echo -e "${YELLOW} - Show pacman progress bar${NC}"

  if [ -f "$conf_file" ]; then
    print_success "Pacman configuration file found"
  else
    print_warning "Pacman configuration file not found"
  fi

  # Enable color: Uncomment or add 'Color'
  if grep -q '^#Color' "$conf_file"; then
    sudo sed -i 's/^#Color/Color/' "$conf_file"
    print_success "Enabled color in pacman."
  elif ! grep -q '^Color' "$conf_file"; then
    echo "Color" | sudo tee -a "$conf_file" >/dev/null
    print_success "Added color option to pacman."
  fi

  # Enable progress bar (ILoveCandy): Uncomment or add 'ILoveCandy'
  if grep -q '^#ILoveCandy' "$conf_file"; then
    sudo sed -i 's/^#ILoveCandy/ILoveCandy/' "$conf_file"
    print_success "Enabled progress bar in pacman."
  elif ! grep -q '^ILoveCandy' "$conf_file"; then
    echo "ILoveCandy" | sudo tee -a "$conf_file" >/dev/null
    print_success "Added progress bar option to pacman."
  fi

  print_success "Pacman configuration updated successfully."
}

# Configure bluetooth
bluetooth_conf() {
  print_message "Configuring bluetooth:"
  echo -e "${YELLOW} - Enable bluetooth kernel module${NC}"
  echo -e "${YELLOW} - Enable and start the bluetooth service${NC}"

  # Enable Bluetooth kernel module (btusb)
  if lsmod | grep -q "^btusb"; then
    print_success "Bluetooth kernel module already enabled."
  else
    sudo modprobe btusb
    if [ $? -eq 0 ]; then
      print_success "Bluetooth kernel module enabled successfully."
    else
      print_error "Failed to enable Bluetooth kernel module."
      exit 1
    fi
  fi

  # Enable and start the Bluetooth service
  if systemctl is-enabled --quiet bluetooth; then
    print_success "Bluetooth service is already enabled."
  else
    sudo systemctl enable bluetooth
    if [ $? -eq 0 ]; then
      print_success "Bluetooth service enabled successfully."
    else
      print_error "Failed to enable Bluetooth service."
      exit 1
    fi
  fi

  # Start the Bluetooth service if not running
  if systemctl is-active --quiet bluetooth; then
    print_success "Bluetooth service is already running."
  else
    sudo systemctl start bluetooth
    if [ $? -eq 0 ]; then
      print_success "Bluetooth service started successfully."
    else
      print_error "Failed to start Bluetooth service."
      exit 1
    fi
  fi

  print_success "Bluetooth configuration completed."
}

# Function to setup dotfiles
setup_dotfiles() {
  if [ -f "./dotfilesSetup.sh" ]; then
    print_success "dotfilesSetup.sh found"
    if confirm "Do you want to run the dotfiles setup script?"; then
      print_message "Running dotfiles setup script.."
      if bash ./dotfilesSetup.sh; then
        print_success "Dotfiles setup script completed successfully"
      else
        print_error "Dotfiles setup failed"
      fi
    else
      print_warning "Skipping dotfiles setup"
    fi
  else
    print_warning "Dotfiles setup script not found"
  fi
}
