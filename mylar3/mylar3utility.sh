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

###################################
####### GET MYLAR INFO ###########
###################################
get_remote_host() {
  while true; do
    read -rp "Enter the remote host (user@hostname): " remote_host
    if validate_remote_host "$remote_host"; then
      echo "Remote host set to $remote_host"
      break
    else
      echo "Invalid remote host format. Please use the format user@hostname"
    fi
  done
}

get_mylar_directory() {
  while true; do
    read -rp "Enter the Mylar3 directory (absolute path): " mylar_directory
    if validate_directory "$mylar_directory"; then
      echo "Mylar3 directory set to $mylar_directory"
      break
    else
      echo "Invalid directory path. Please enter a valid directory path."
    fi
  done
}

get_backup_directory() {
  while true; do
    read -rp "Enter the backup directory (absolute path): " backup_directory
    if validate_directory "$backup_directory"; then
      echo "Backup directory set to $backup_directory"
      break
    else
      echo "Invalid directory path. Please enter a valid directory path."
    fi
  done
}

get_mylar_api_key() {
  read -rp "Enter your Mylar3 API key: " mylar_api_key
  echo "Mylar3 API key set."
}

get_mylar_port() {
  while true; do
    read -rp "Enter the Mylar3 port (default: 8090): " mylar_port
    if [[ $mylar_port =~ ^[0-9]+$ ]] && [ "$mylar_port" -ge 1 ] && [ "$mylar_port" -le 65535 ]; then
      echo "Mylar3 port set to $mylar_port"
      break
    else
      echo "Invalid port number. Please enter a valid port number between 1 and 65535."
    fi
  done
}

remote_exec() {
  ssh "$remote_host" "$1"
}

# Get all configuration settings at the start
get_remote_host
get_mylar_directory
get_backup_directory
get_mylar_api_key
get_mylar_port

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

while true; do
  echo "
  Mylar3 Utility Script
  1. Check Mylar3 status
  2. Start Mylar3 service
  3. Stop Mylar3 service
  4. Restart Mylar3 service
  5. Update Mylar3 service
  6. Backup Mylar3 database
  7. Trigger library scan
  8. Check for missing issues
  9. Change remote host
  10. Change Mylar3 directory
  11. Change backup directory
  12. Change Mylar3 API key
  13. Change Mylar3 port
  14. Exit
  "

  read -p "Enter your choice: " choice

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
