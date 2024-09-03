#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh

################################################################################

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
