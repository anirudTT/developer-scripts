#!/bin/bash

# Initialize REMOVE_EXISTING flag
REMOVE_EXISTING=false

# Usage function to display help
usage() {
    echo "Usage: $0 [-r] [-h]"
    echo "  -r    Remove existing directories and Python environments before deployment."
    echo "  -h    Display this help and exit."
}

# Parse flags
while getopts "rh" flag; do
    case "${flag}" in
        r) REMOVE_EXISTING="true" ;;
        h) usage
           exit ;;
        *) usage
           exit 1 ;;
    esac
done

# Ask for the GitLab release URL
read -p "Enter the GitLab release URL: " gitlab_url

#  Read Content from hosts file
echo "Reading host configurations:"

HOSTS=()
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Host read: '$line'"
    HOSTS+=("$line")
done < "hosts.config"

if [ ${#HOSTS[@]} -eq 0 ]; then
    echo "No hosts read from file."
else
    echo "Deploying to the following hosts:"
    printf '%s\n' "${HOSTS[@]}"
fi



