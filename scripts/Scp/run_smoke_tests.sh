#!/bin/bash

# Smoke test script to verify the setup of Python environments on remote hosts

# Usage example: ./run_smoke_tests.sh hosts.config /path/to/local/smoke_test.py

# Check if input arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hosts_config> <path_to_smoke_test_py>"
    exit 1
fi

HOSTS_CONFIG="$1"
SMOKE_TEST_PY="$2"

# Read remote host details from hosts.config
echo "Reading host configurations from $HOSTS_CONFIG:"
HOSTS=()
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Host read: '$line'"
    HOSTS+=("$line")
done < "$HOSTS_CONFIG"

if [ ${#HOSTS[@]} -eq 0 ]; then
    echo "No hosts read from file. Please check the file content."
    exit 1
fi

echo "Running smoke tests on the following hosts:"
printf '%s\n' "${HOSTS[@]}"

# Loop through each host and run the smoke tests
for HOST in "${HOSTS[@]}"; do
    REMOTE_USER=${HOST%@*}
    REMOTE_HOST=${HOST#*@}

    # Assume the deployment date directory to get the path to the installed environment
    DESTINATION_DIR="/home/$REMOTE_USER/Releases/$(date +%d_%B_%Y)"

    echo "Running smoke tests on $REMOTE_HOST..."
    echo "Using directory $DESTINATION_DIR..."

    # Copy the smoke test Python script to the remote host
    if ! scp "$SMOKE_TEST_PY" "$REMOTE_USER@$REMOTE_HOST:$DESTINATION_DIR/smoke_test.py"; then
        echo "Failed to copy smoke test script to $REMOTE_HOST."
        continue # Skip this host and continue with the next one
    fi

    # Execute smoke test Python script on the remote host
    ssh "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
        echo "Accessing directory at $DESTINATION_DIR"
        cd "$DESTINATION_DIR" || exit 1
        source python_env/bin/activate
        echo "Running detailed smoke test..."
        python smoke_test.py
EOF
    if [ $? -ne 0 ]; then
        echo "An error occurred while running smoke tests on $REMOTE_HOST."
    else
        echo "Smoke tests passed successfully on $REMOTE_HOST."
    fi
done

echo "Smoke test execution completed!"
