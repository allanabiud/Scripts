#!/bin/bash
# Author: Allan Nyagaka

# Mylar3 Utility Script

################################################################################
######################## GLOBAL VARIABLES ######################################
################################################################################
# Global variables
MYLAR_SERVICE="mylar3"

################################################################################
########################### FUNCTIONS ##########################################
################################################################################

##################################
######### COLORS ###############
##################################
RED='\033[0;31m' # Red
# RED_BOLD='\033[1;31m' # Bold Red
GREEN='\033[0;32m' # Green
# GREEN_BOLD='\033[1;32m' # Bold Green
YELLOW='\033[0;33m' # Yellow
# YELLOW_BOLD='\033[1;33m' # Bold Yellow
BLUE='\033[0;34m' # Blue
# BLUE_BOLD='\033[1;34m' # Bold Blue
NC='\033[0m' # No Color

###################################
######### VALIDATION #############
###################################
# Function to validate remote host syntax
validate_remote_host() {
  if [[ $1 =~ ^[a-zA-Z0-9_-]+@[a-zA-Z0-9._-]+$ ]]; then
    return 0
  else
    return 1
  fi
}
# Function to validate directory path
validate_directory() {
  remote_exec "[ -d \"$1\" ]"
  return $?
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

###################################
####### GET MYLAR INFO ###########
###################################
get_remote_host() {
  while true; do
    print_message "Enter the remote host (user@hostname):"
    read -rp " " remote_host
    if validate_remote_host "$remote_host"; then
      print_success "Remote host set to ${YELLOW}$remote_host${NC}"
      break
    else
      print_error "Invalid remote host format. Please use the format ${YELLOW}user@hostname${NC}."
    fi
  done
}

get_mylar_directory() {
  while true; do
    print_message "Enter the Mylar3 directory (absolute path):"
    read -rp " " mylar_directory
    if validate_directory "$mylar_directory"; then
      print_success "Mylar3 directory set to ${YELLOW}$mylar_directory${NC}"
      break
    else
      print_error "Invalid directory path. Please enter a valid directory path."
    fi
  done
}

get_backup_directory() {
  while true; do
    print_message "Enter the backup directory (absolute path):"
    read -rp " " backup_directory
    if validate_directory "$backup_directory"; then
      print_success "Backup directory set to ${YELLOW}$backup_directory${NC}"
      break
    else
      print_error "Invalid directory path. Please enter a valid directory path."
    fi
  done
}

get_mylar_api_key() {
  while true; do
    print_message "Enter your Mylar3 API key:"
    read -rp " " mylar_api_key
    if [[ $mylar_api_key =~ ^[a-zA-Z0-9]+$ ]]; then
      print_success "Mylar3 API key set."
      break
    else
      print_error "Invalid Mylar3 API key. Please enter a valid Mylar3 API key."
    fi
  done
}

get_mylar_port() {
  while true; do
    print_message "Enter the Mylar3 port (default: 8090):"
    read -rp " " mylar_port
    if [[ $mylar_port =~ ^[0-9]+$ ]] && [ "$mylar_port" -ge 1 ] && [ "$mylar_port" -le 65535 ]; then
      print_success "Mylar3 port set to ${YELLOW}$mylar_port${NC}"
      break
    else
      print_error "Invalid port number. Please enter a valid port number between 1 and 65535."
    fi
  done
}

remote_exec() {
  ssh "$remote_host" "$1"
}

# Function to check Mylar3 service status
check_status() {
  remote_exec "systemctl is-active --quiet $MYLAR_SERVICE && echo 'Mylar3 is running' || echo 'Mylar3 is not running.'"
}

# Function to start Mylar3 service
start_service() {
  remote_exec "sudo systemctl start $MYLAR_SERVICE && echo 'Mylar3 service started successfully' || echo 'Failed to start Mylar3 service.'"
}

# Function to stop Mylar3 service
stop_service() {
  remote_exec "sudo systemctl stop $MYLAR_SERVICE && echo 'Mylar3 service stopped successfully' || echo 'Failed to stop Mylar3 service.'"
}

# Function to restart Mylar3 service
restart_service() {
  remote_exec "sudo systemctl restart $MYLAR_SERVICE && echo 'Mylar3 service restarted successfully' || echo 'Failed to restart Mylar3 service.'"
}

# Function to update Mylar3 service
update_service() {
  remote_exec "cd $mylar_directory && git pull && pip install -r requirements.txt --upgrade && echo 'Mylar3 updated. Please restart the service.'"
}

# Function to backup Mylar3 database
backup_database() {
  TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
  BACKUP_FILE="$backup_directory/mylar3_backup_$TIMESTAMP.db"
  remote_exec "cp $mylar_directory/data/mylar.db $BACKUP_FILE && echo 'Mylar3 database backed up to $BACKUP_FILE'"
}

# Function to trigger a library scan
library_scan() {
  remote_exec "curl -X POST http://localhost:$mylar_port/api?apikey=$mylar_api_key&cmd=forceSearch && echo 'Library scan triggered.'"
}

# Function to check for and download missing issues
check_missing() {
  remote_exec "curl -X POST http://localhost:$mylar_port/api?apikey=$mylar_api_key&cmd=updateissues && echo 'Checking for and downloading missing issues.'"
}

################################################################################
############################ MAIN SCRIPT #######################################
################################################################################

clear

# Get all configuration settings at the start
get_remote_host
get_mylar_directory
get_backup_directory
get_mylar_api_key
get_mylar_port

while true; do
  clear -x

  print_message "Mylar3 Utility Script"
  echo -e "${YELLOW}1. Start Mylar3 service${NC}"
  echo -e "${YELLOW}2. Stop Mylar3 service${NC}"
  echo -e "${YELLOW}3. Restart Mylar3 service${NC}"
  echo -e "${YELLOW}4. Update Mylar3 service${NC}"
  echo -e "${YELLOW}5. Backup Mylar3 database${NC}"
  echo -e "${YELLOW}6. Trigger library scan${NC}"
  echo -e "${YELLOW}7. Check for missing issues${NC}"
  echo -e "${YELLOW}8. Change remote host${NC}"
  echo -e "${YELLOW}9. Change Mylar3 directory${NC}"
  echo -e "${YELLOW}10. Change backup directory${NC}"
  echo -e "${YELLOW}11. Change Mylar3 API key${NC}"
  echo -e "${YELLOW}12. Change Mylar3 port${NC}"
  echo -e "${YELLOW}13. Exit${NC}"

  print_message "Enter your choice:"
  read -rp " " choice

  case $choice in
  1)
    check_status
    ;;
  2)
    start_service
    ;;
  3)
    stop_service
    ;;
  4)
    restart_service
    ;;
  5)
    update_service
    ;;
  6)
    backup_database
    ;;
  7)
    library_scan
    ;;
  8)
    check_missing
    ;;
  9)
    get_remote_host
    ;;
  10)
    get_mylar_directory
    ;;
  11)
    get_backup_directory
    ;;
  12)
    get_mylar_api_key
    ;;
  13)
    get_mylar_port
    ;;
  14)
    exit
    ;;
  *)
    echo "Invalid choice. Please enter a valid choice."
    ;;
  esac

  echo
  read -rp "Press enter to continue..."
done
