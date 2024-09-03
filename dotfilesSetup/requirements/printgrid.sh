#!/bin/bash
# shellcheck disable=1091

# Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh

################################################################################

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
