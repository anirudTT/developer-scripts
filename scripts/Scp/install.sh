#!/bin/bash

# Initialize REMOVE_EXISTING flag
REMOVE_EXISTING=false

# Usage function to display help
usage() {
    echo "Usage: $0 [-r] [-h]"
    echo "  -r    Remove existing directories and Python environments before deployment."
    echo "  -h    Display this help and exit."
    exit 1
}

# Parse flags
while getopts "rh" flag; do
    case "${flag}" in
        r) REMOVE_EXISTING=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Ask for the GitLab release URL
read -p "Enter the GitLab release URL: " gitlab_url

# Read remote host details from hosts.config
echo "Reading host configurations:"
HOSTS=()
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Host read: '$line'"
    HOSTS+=("$line")
done < "hosts.config"

if [ ${#HOSTS[@]} -eq 0 ]; then
    echo "No hosts read from file. Please check the file content."
    exit 1
fi
echo "Deploying to the following hosts:"
printf '%s\n' "${HOSTS[@]}"

# The name of the downloaded file
ZIP_FILE="release.zip"

# Download the release
if ! wget "$gitlab_url" -O "$ZIP_FILE"; then
    echo "Failed to download the file from GitLab."
    exit 1
fi

# Ensure the file was downloaded and is not empty
if [ ! -s "$ZIP_FILE" ]; then
    echo "Downloaded file is empty or missing."
    exit 1
fi

# Loop through each host and perform the operations
for HOST in "${HOSTS[@]}"; do
    REMOTE_USER=${HOST%@*}
    REMOTE_HOST=${HOST#*@}

    # Define the destination directory using the user name
    DESTINATION_DIR="/home/$REMOTE_USER/Releases/$(date +%d_%B_%Y)"

    echo "Preparing to deploy to $REMOTE_HOST..."
    echo "Destination directory will be $DESTINATION_DIR"

    # Ensure the directory exists on the remote host
    if ! ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$DESTINATION_DIR'"; then
        echo "Failed to create directory on $REMOTE_HOST."
        continue # Skip this host and continue with the next one
    fi

    # SCP the file to the remote host
    if ! scp "$ZIP_FILE" "$REMOTE_USER@$REMOTE_HOST:$DESTINATION_DIR"; then
        echo "Failed to copy the file to $REMOTE_HOST."
        continue # Skip this host and continue with the next one
    fi

    # Execute commands on the remote host
    ssh "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
        if [ "$REMOVE_EXISTING" = "true" ]; then
            echo "Removing existing directory at $DESTINATION_DIR"
            rm -rf "$DESTINATION_DIR"
            mkdir -p "$DESTINATION_DIR"
        fi
        echo "Directory ensured at $DESTINATION_DIR"
        cd "$DESTINATION_DIR" || exit
        echo "Unzipping file..."
        if ! unzip -o "$ZIP_FILE"; then
            echo "Failed to unzip the file on $REMOTE_HOST."
            exit 1
        fi
        echo "Setting up Python environment..."
        python3 -m venv python_env
        source python_env/bin/activate
        if ! pip install --upgrade pip==24.0; then
            echo "Failed to upgrade pip on $REMOTE_HOST."
            exit 1
        fi
        echo "Installing wheel files..."
        if ! pip install *.whl; then
            echo "Failed to install wheel files on $REMOTE_HOST."
            exit 1
        fi
EOF
    if [ $? -ne 0 ]; then
        echo "An error occurred while setting up the environment on $REMOTE_HOST."
    else
        echo "Successfully set up the environment on $REMOTE_HOST."
    fi
done

echo "Deployment completed!"
