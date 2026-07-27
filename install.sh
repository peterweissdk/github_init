#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: install.sh
# Description: Install github_init.sh script
# Author: peterweissdk
# Usage: curl -fsSL https://raw.githubusercontent.com/peterweissdk/github_init/main/install.sh | bash
# ----------------------------------------------------------------------------

SCRIPT_NAME="github_init.sh"
REPO_URL="https://raw.githubusercontent.com/peterweissdk/github_init/main/github_init.sh"
DEFAULT_PATH="/usr/local/bin"

echo "Installing $SCRIPT_NAME..."

# Use default path when piped (non-interactive)
install_path="$DEFAULT_PATH"

# Create temp file
tmp_file=$(mktemp)
trap "rm -f $tmp_file" EXIT

# Download the script
echo "Downloading $SCRIPT_NAME..."
if ! curl -fsSL "$REPO_URL" -o "$tmp_file"; then
    echo "Error: Failed to download script"
    exit 1
fi

# Install the script
echo "Installing to $install_path/$SCRIPT_NAME..."
if [ ! -w "$install_path" ]; then
    echo "You need root privileges to install the script in $install_path."
    if sudo cp "$tmp_file" "$install_path/$SCRIPT_NAME" && sudo chmod +x "$install_path/$SCRIPT_NAME"; then
        echo "Script installed successfully to $install_path/$SCRIPT_NAME"
    else
        echo "Error: Failed to install script"
        exit 1
    fi
else
    if cp "$tmp_file" "$install_path/$SCRIPT_NAME" && chmod +x "$install_path/$SCRIPT_NAME"; then
        echo "Script installed successfully to $install_path/$SCRIPT_NAME"
    else
        echo "Error: Failed to install script"
        exit 1
    fi
fi

echo "Run '$SCRIPT_NAME' to create a new GitHub repository."
