#!/bin/bash

ZIP_DIRECTORY="../Releases/"
DEPLOY_SCRIPT="./scp_copy_and_install_python.sh"
SMOKE_TEST_SCRIPT="./run_smoke_tests.sh"
REMOVE_EXISTING=false
RUN_INSTALLS=false
RUN_SMOKE_TESTS=false

usage() {
    echo "Usage: $0 [-r] [-i] [-s]"
    echo "  -r    Remove existing directories and Python environments before deployment."
    echo "  -i    Perform installations after deployment."
    echo "  -s    Run smoke tests after deployment."
    exit 1
}

while getopts "rish" opt; do
    case "$opt" in
        r) REMOVE_EXISTING=true ;;
        i) RUN_INSTALLS=true ;;
        s) RUN_SMOKE_TESTS=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ ! -f "$DEPLOY_SCRIPT" ]; then
    echo "Deployment script not found: $DEPLOY_SCRIPT"
    exit 1
fi

ZIP_FILES=$(find "$ZIP_DIRECTORY" -type f -name '*.zip')

if [ -z "$ZIP_FILES" ]; then
    echo "No ZIP files found in $ZIP_DIRECTORY."
    exit 1
fi

DEPLOY_OPTIONS=""
if [ "$REMOVE_EXISTING" = true ]; then
    DEPLOY_OPTIONS="-r"
fi

for ZIP_FILE in $ZIP_FILES; do
    if [ "$RUN_INSTALLS" = true ]; then
        echo "Running deployment for $ZIP_FILE with options: $DEPLOY_OPTIONS"
        $DEPLOY_SCRIPT $DEPLOY_OPTIONS -z "$ZIP_FILE"
    fi

    if [ "$RUN_SMOKE_TESTS" = true ]; then
        echo "Running smoke tests for $ZIP_FILE"
        HOSTS_CONFIG_PATH="./hosts.config"
        SMOKE_TEST_PY_PATH="./smoke_test.py"
        $SMOKE_TEST_SCRIPT $HOSTS_CONFIG_PATH $SMOKE_TEST_PY_PATH
    fi
done

echo "Deployment completed for all ZIP files in $ZIP_DIRECTORY"
