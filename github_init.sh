#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: github_init.sh
# Description: Create Github and Git repositories
# Author: peterweissdk
# Email: peterweissdk@flems.dk
# Date: 2025-01-07
# Version: v0.1.3
# Usage: Run script and follow instructions
# ----------------------------------------------------------------------------

# Installs script
install() {
    read -p "Do you want to install this script? (yes/no): " answer
    case $answer in
        [Yy]* )
            # Set default installation path
            default_path="/usr/local/bin"
            
            # Prompt for installation path
            read -p "Enter the installation path [$default_path]: " install_path
            install_path=${install_path:-$default_path}  # Use default if no input

            # Get the filename of the script
            script_name=$(basename "$0")

            # Copy the script to the specified path
            echo "Copying $script_name to $install_path..."
            
            # Check if the user has write permissions
            if [ ! -w "$install_path" ]; then
                echo "You need root privileges to install the script in $install_path."
                if sudo cp "$0" "$install_path/$script_name"; then
                    sudo chmod +x "$install_path/$script_name"
                    echo "Script installed successfully."
                else
                    echo "Failed to install script."
                    exit 1
                fi
            else
                if cp "$0" "$install_path/$script_name"; then
                    chmod +x "$install_path/$script_name"
                    echo "Script installed successfully."
                else
                    echo "Failed to install script."
                    exit 1
                fi
            fi
            ;;
        [Nn]* )
            echo "Exiting script."
            exit 0
            ;;
        * )
            echo "Please answer yes or no."
            install
            ;;
    esac

    exit 0
}

# Updates version of script
update_version() {
    # Extract the current version from the script header
    version_line=$(grep "^# Version:" "$0")
    current_version=${version_line#*: }  # Remove everything up to and including ": "
    
    echo "Current version: $current_version"
    
    # Prompt the user for a new version
    read -p "Enter new version (current: $current_version): " new_version
    
    # Update the version in the script
    sed -i "s/^# Version: .*/# Version: $new_version/" "$0"
    
    echo "Version updated to: $new_version"

    exit 0
}

# Prints out version
version() {
    # Extract the current version from the script header
    version_line=$(grep "^# Version:" "$0")
    current_version=${version_line#*: }  # Remove everything up to and including ": "
    
    echo "$0: $current_version"

    exit 0
}

# Prints out help
help() {
    echo "Run script to setup a new shell script file."
    echo "Usage: $0 [-i | --install] [-u | --update-version] [-v | --version] [-h | --help]"

    exit 0
}

# Check for flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--install) install; shift ;;
        -u|--update-version) update_version; shift ;;
        -v|--version) version; shift ;;
        -h|--help) help; shift ;;
        *) echo "Unknown option: $1"; help; exit 1 ;;
    esac
done


# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to create SSH key
create_ssh_key() {
    local project_name=$1
    local key_name="github_auth_${project_name}"
    echo
    read -p "Do you want to create a new SSH key for GitHub authentication? (y/n): " create_key
    if [[ $create_key == "y" || $create_key == "Y" ]]; then
        ssh-keygen -t ed25519 -f ~/.ssh/${key_name} -N ""
        echo "SSH key created at ~/.ssh/${key_name}"
        echo "Public key content (add this to GitHub):"
        cat ~/.ssh/${key_name}.pub
    fi
}

# Welcome message
echo "###############################"
echo "GitHub repository setup script!"
echo "###############################"

# Check for GitHub CLI
if ! check_command "gh"; then
    echo
    echo "GitHub CLI (gh) is not installed."
    echo "To install on Ubuntu/Debian: sudo apt install gh"
    echo "To install on Fedora: sudo dnf install gh"
    echo "to install on Arch: pacman -S github-cli"
    echo "For other distributions, visit: https://github.com/cli/cli#installation"
    exit 1
fi

# Check for Git
if ! check_command "git"; then
    echo
    echo "Git is not installed."
    echo "To install on Ubuntu/Debian: sudo apt install git"
    echo "To install on Fedora: sudo dnf install git"
    echo "to install on Arch: pacman -S git"
    exit 1
fi

# Get project name
echo
read -p "Enter your GitHub project name: " project_name

# Create SSH key if requested
create_ssh_key "$project_name"

# Login to GitHub
echo
if ! gh auth status &>/dev/null; then
    echo
    echo "Logging in to GitHub..."
    gh auth login
else
    echo
    echo "Already logged in to GitHub"
fi

# Get GitHub username
echo
GITHUB_USERNAME=$(gh api user -q .login)
echo "GitHub username: $GITHUB_USERNAME"

# Check if project exists on GitHub (works for both public and private repos)
while gh repo view "$GITHUB_USERNAME/$project_name" &>/dev/null; do
    echo
    echo "Error: Repository '$project_name' already exists on GitHub"
    echo
    read -p "Enter (n)ew project name or e(x)it: " choice
    case $choice in
        [nN])
            echo
            read -p "Enter your GitHub project name: " project_name
            ;;
        [xX])
            echo "Exiting script..."
            exit 1
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            ;;
    esac
done

# Get repository visibility
echo
read -p "Should the repository be private? (y/n): " is_private
if [[ $is_private == "y" || $is_private == "Y" ]]; then
    visibility="--private"
else
    visibility="--public"
fi

# Get license information
echo
read -p "Do you want to add a license? (y/n): " add_license
if [[ $add_license == "y" || $add_license == "Y" ]]; then
    echo "Available licenses:"
    echo "    1  - MIT License (mit)"
    echo "    2  - Apache License 2.0 (apache-2.0)"
    echo "    3  - GNU General Public License v3.0 (gpl-3.0)"
    echo "    4  - GNU General Public License v2.0 (gpl-2.0)"
    echo "    5  - GNU Lesser General Public License v3.0 (lgpl-3.0)"
    echo "    6  - BSD 3-Clause License (bsd-3-clause)"
    echo "    7  - BSD 2-Clause License (bsd-2-clause)"
    echo "    8  - Mozilla Public License 2.0 (mpl-2.0)"
    echo "    9  - Eclipse Public License 2.0 (epl-2.0)"
    echo "    10 - Unlicense (unlicense)"
    echo "    11 - Creative Commons Zero v1.0 Universal (cc0-1.0)"
    echo
    while true; do
        read -p "Enter license number (1-11): " license_number
        case $license_number in
            1)  license_type="mit" ; break ;;
            2)  license_type="apache-2.0" ; break ;;
            3)  license_type="gpl-3.0" ; break ;;
            4)  license_type="gpl-2.0" ; break ;;
            5)  license_type="lgpl-3.0" ; break ;;
            6)  license_type="bsd-3-clause" ; break ;;
            7)  license_type="bsd-2-clause" ; break ;;
            8)  license_type="mpl-2.0" ; break ;;
            9)  license_type="epl-2.0" ; break ;;
            10) license_type="unlicense" ; break ;;
            11) license_type="cc0-1.0" ; break ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 11."
                echo
                ;;
        esac
    done
    license_flag="--license $license_type"
else
    license_flag=""
fi

# Create repository
echo
echo "Creating GitHub repository..."
gh repo create "$project_name" $visibility $license_flag

# Get clone path
echo
read -p "Enter the path where you want to clone the repository: " clone_path

# Check if directory exists
while [ -d "$clone_path" ]; do
    echo "Error: Directory '$clone_path' already exists"
    echo
    read -p "Enter (n)ew path or e(x)it: " choice
    case $choice in
        [nN])
            echo
            read -p "Enter the path where you want to clone the repository: " clone_path
            ;;
        [xX])
            echo "Exiting script..."
            exit 1
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            ;;
    esac
done

# Clone repository
echo
echo "Cloning repository..."
gh repo clone "$project_name" "$clone_path"

# Change to repository directory and show status
echo
cd "$clone_path" || exit
echo "Repository status:"
git status

# Verify repository was created and cloned successfully
if [ -d "$clone_path/.git" ] && [ -n "$(git remote -v)" ]; then
    echo
    echo "Repository setup completed successfully!"
    echo "Go to the About section of your GitHub repository and set Description, Website and Topics."
    exit 0
else
    echo
    echo "Error: Repository setup may not have completed successfully"
    exit 1
fi
