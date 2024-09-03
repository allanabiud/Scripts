#!/bin/bash
# shellcheck disable=1091

## Source other functions
# Check if colors.sh exists
source ./requirements/colors.sh
source ./requirements/confirmation.sh
source ./requirements/messages.sh

################################################################################

# Function to handle existing config files
handle_existing_dotfiles() {
	local file=$1
	local target_path="$HOME/.config/$file"

	if [ -e "$target_path" ] || [ -L "$target_path" ]; then
		while true; do
			if [ -L "$target_path" ]; then
				local link_target
				link_target=$(readlink -f "$target_path")
				# Broken symlink
				if [ ! -e "$link_target" ]; then
					print_warning "File or directory $target_path is a broken symlink pointing to non-existent file or directory."
					echo -e "${YELLOW} 1) Delete the broken symlink and proceed"
					echo -e "${YELLOW} 2) Skip stowing this file"
					echo -e -n "${BLUE} Select an option: (1/2): ${NC}"
					read -r choice
					case $choice in
					1)
						if confirm "Are you sure you want to delete the broken symlink?"; then
							rm -rf "$target_path"
							print_success "Removed broken symlink $target_path"
							return 0
						else
							print_message "Skipping $target_path"
							return 1
						fi
						;;
					2)
						print_message "Skipping $target_path"
						return 1
						;;
					*)
						print_error "Invalid option. Please select an option from the list."
						continue
						;;
					esac
				elif [[ "$link_target" == "$HOME/dotfiles/*" ]]; then
					# Symlinked to another package
					print_warning "File or directory $target_path is already stowed by another package in dotfiles repo."
					echo -e "${YELLOW} 1) Overwrite (unstow other package and stow this package)"
					echo -e "${YELLOW} 2) Skip stowing this file"
					echo -e -n "${BLUE} Select an option: (1/2): ${NC}"
					read -r choice
					case $choice in
					1)
						local stow_dir
						local package
						stow_dir=$(dirname "$(dirname "$link_target")")
						package=$(basename "$(dirname "$link_target")")
						if confirm "Are you sure you want to unstow $package?"; then
							stow -D -d "$stow_dir" "$package"
							print_success "Unstowed package $package"
							rm -rf "$target_path"
							print_success "Removed $target_path"
							return 0
						else
							print_message "Skipping $target_path"
							return 1
						fi
						;;
					2)
						print_message "Skipping $target_path"
						return 1
						;;
					*)
						print_error "Invalid option. Please select an option from the list."
						continue
						;;
					esac
				else
					# Symlinked to location outside of stow packages in dotfiles repo
					print_warning "File or directory $target_path is already symlinked to $link_target."
					echo -e "${YELLOW} 1) Overwrite symlink"
					echo -e "${YELLOW} 2) Backup symlink and replace"
					echo -e "${YELLOW} 3) Skip stowing this file"
					echo -e -n "${BLUE} Select an option (1/2/3): ${NC}"
					read -r choice
					case $choice in
					1)
						if confirm "Are you sure you want to overwrite $target_path?"; then
							rm -rf "$target_path"
							print_success "Removed $target_path"
							return 0
						else
							print_message "Skipping $target_path"
							return 1
						fi
						;;
					2)
						if confirm "Are you sure you want to backup $target_path?"; then
							mv "$target_path" "${target_path}.backup"
							print_success "Existing file or directory backed up as ${file}.backup"
							return 0
						else
							print_message "Skipping $target_path"
							return 1
						fi
						;;
					3)
						print_message "Skipping $target_path"
						return 1
						;;
					*)
						print_error "Invalid option. Please select an option from the list."
						continue
						;;
					esac
				fi
			else
				# Regular file
				print_warning "File or directory $target_path already exists."
				echo -e "${YELLOW} 1) Overwrite"
				echo -e "${YELLOW} 2) Backup and replace"
				echo -e "${YELLOW} 3) Skip stowing this file"
				echo -e -n "${BLUE} Select an option (1/2/3): ${NC}"
				read -r choice
				case $choice in
				1)
					if confirm "Are you sure you want to overwrite $target_path?"; then
						rm -rf "$target_path"
						print_success "Removed $target_path"
						return 0
					else
						print_message "Skipping $target_path"
						return 1
					fi
					;;
				2)
					if confirm "Are you sure you want to backup $target_path?"; then
						mv "$target_path" "${target_path}.backup"
						print_success "Existing file or directory backed up as ${file}.backup"
						return 0
					else
						print_message "Skipping $target_path"
						return 1
					fi
					;;
				3)
					print_message "Skipping $target_path"
					return 1
					;;
				*)
					print_error "Invalid option. Please select an option from the list."
					continue
					;;
				esac
			fi
		done
	fi
	return 0
}
