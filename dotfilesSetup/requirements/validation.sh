#!/bin/bash

# Function to validate Git URL
validate_git_url() {
	local url=$1
	# Basic regex to validate Git URLs
	local git_url_regex='^((https?://|git@|git://)([[:alnum:]_.-]+@)?[[:alnum:]_.-]+)(:|/)[[:alnum:]_.-]+/[[:alnum:]_.-]+(.git)?$'
	if [[ $url =~ $git_url_regex ]]; then
		return 0
	else
		return 1
	fi
}
# Function to validate directory path
validate_directory_path() {
	local path=$1
	# Empty tilde expansion to home directory
	path=${path/#\~/$HOME}
	# Check if path contains only allowed characters
	if [[ "$path" =~ ^[a-zA-Z0-9_/.-]+$ ]]; then
		return 0
	else
		return 1
	fi
}
