#!/bin/bash

REMOVE_EXISTING=false
ZIP_FILE=""

usage() {
    echo "Usage: $0 [-r] [-z zip_file_path]"
    echo "  -r    Remove existing directories and Python environments before deployment."
    echo "  -z    Specify the path to the ZIP file to deploy."
    echo "  -h    Display this help and exit."
    exit 1
}

while getopts "rhz:" opt; do
    case "$opt" in
        r) REMOVE_EXISTING=true ;;
        z) ZIP_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -z "$ZIP_FILE" ]; then
    echo "No ZIP file provided."
    usage
fi

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

# Verify the integrity of the ZIP file
if [ ! -s "$ZIP_FILE" ] || ! unzip -tq "$ZIP_FILE"; then
    echo "Zip file is corrupt or not a valid ZIP archive."
    exit 1
fi

# Loop through each host and perform the operations
for HOST in "${HOSTS[@]}"; do
    REMOTE_USER=${HOST%@*}
    REMOTE_HOST=${HOST#*@}
    DESTINATION_DIR="/home/$REMOTE_USER/Releases/$(date +%d_%B_%Y)"
    echo "Preparing to deploy to $REMOTE_HOST..."
    echo "Destination directory will be $DESTINATION_DIR"

    ssh "$REMOTE_USER@$REMOTE_HOST" bash -s <<EOF
        if [ "$REMOVE_EXISTING" = "true" ]; then
            echo "Removing existing directory at $DESTINATION_DIR"
            rm -rf "$DESTINATION_DIR"
        fi
        echo "Creating directory at $DESTINATION_DIR"
        mkdir -p "$DESTINATION_DIR"
EOF

    if [ $? -ne 0 ]; then
        echo "Failed to prepare directory on $REMOTE_HOST."
        continue
    fi

    if ! scp "$ZIP_FILE" "$REMOTE_USER@$REMOTE_HOST:$DESTINATION_DIR"; then
        echo "Failed to copy the file to $REMOTE_HOST."
        continue
    fi

    ssh "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
        echo "Directory ensured at $DESTINATION_DIR"
        cd "$DESTINATION_DIR" || exit
        echo "Unzipping file..."
        if ! unzip -o "$(basename "$ZIP_FILE")"; then
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
        echo "Installing pybuda and PyTorch..."
        if ! pip install pybuda torch; then
            echo "Failed to install pybuda and PyTorch on $REMOTE_HOST."
            exit 1
        fi
EOF

    if [ $? -ne 0 ]; then
        echo "An error occurred while setting up the environment on $REMOTE_HOST."
    else
        echo "Successfully set up the environment on $REMOTE_HOST."
    fi
done

echo "Deployment of ZIP file and installation of .whl files and Python environment completed!"
