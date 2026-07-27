#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: github_init.sh
# Description: Create Github and Git repositories
# Author: peterweissdk
# Email: peterweissdk@flems.dk
# Date: 2025-01-07
# Version: v0.1.4
# Usage: Run script and follow instructions
# ----------------------------------------------------------------------------

# Updates script from GitHub
update() {
    local current_version="v0.1.4"
    local repo_url="https://raw.githubusercontent.com/peterweissdk/github_init/main/github_init.sh"
    
    echo "Current version: $current_version"
    echo "Checking for updates..."
    
    # Get remote version
    remote_version=$(curl -fsSL "$repo_url" | grep "^# Version:" | cut -d' ' -f3)
    
    if [ -z "$remote_version" ]; then
        echo "Error: Could not fetch remote version"
        exit 1
    fi
    
    echo "Remote version: $remote_version"
    
    if [ "$current_version" = "$remote_version" ]; then
        echo "You are already running the latest version."
        exit 0
    fi
    
    echo "Update available: $current_version -> $remote_version"
    read -p "Do you want to update? (y/n): " answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
    
    # Download and replace script
    tmp_file=$(mktemp)
    trap "rm -f $tmp_file" EXIT
    
    if ! curl -fsSL "$repo_url" -o "$tmp_file"; then
        echo "Error: Failed to download update"
        exit 1
    fi
    
    # Get the path of the current script
    script_path=$(realpath "$0")
    
    # Check if we need sudo
    if [ ! -w "$script_path" ]; then
        echo "You need root privileges to update the script."
        if sudo cp "$tmp_file" "$script_path" && sudo chmod +x "$script_path"; then
            echo "Script updated successfully to $remote_version"
        else
            echo "Error: Failed to update script"
            exit 1
        fi
    else
        if cp "$tmp_file" "$script_path" && chmod +x "$script_path"; then
            echo "Script updated successfully to $remote_version"
        else
            echo "Error: Failed to update script"
            exit 1
        fi
    fi

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
    echo "Run script to setup a new GitHub repository."
    echo "Usage: $0 [-u | --update] [-v | --version] [-h | --help]"

    exit 0
}

# Check for flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--update) update; shift ;;
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

# Get user's organizations
echo
echo "Fetching organizations..."
ORGS=$(gh api user/orgs -q '.[].login' 2>/dev/null)

# Select organization or personal account
echo
echo "Where do you want to create the repository?"
echo "    0 - Personal account ($GITHUB_USERNAME)"
if [ -n "$ORGS" ]; then
    ORG_ARRAY=($ORGS)
    for i in "${!ORG_ARRAY[@]}"; do
        echo "    $((i+1)) - ${ORG_ARRAY[$i]}"
    done
fi
echo

while true; do
    read -p "Enter your choice: " org_choice
    if [[ "$org_choice" == "0" ]]; then
        REPO_OWNER="$GITHUB_USERNAME"
        ORG_FLAG=""
        break
    elif [ -n "$ORGS" ] && [[ "$org_choice" =~ ^[0-9]+$ ]] && [ "$org_choice" -ge 1 ] && [ "$org_choice" -le "${#ORG_ARRAY[@]}" ]; then
        REPO_OWNER="${ORG_ARRAY[$((org_choice-1))]}"
        ORG_FLAG="--org $REPO_OWNER"
        break
    else
        echo "Invalid choice. Please try again."
        echo
    fi
done
echo "Repository will be created in: $REPO_OWNER"

# Check if project exists on GitHub (works for both public and private repos)
while gh repo view "$REPO_OWNER/$project_name" &>/dev/null; do
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
gh repo create "$project_name" $visibility $license_flag $ORG_FLAG

# Get clone path
echo
read -p "Enter the path where you want to clone the repository: " clone_path

# Validate clone path
validate_path() {
    local path="$1"
    local parent_dir
    parent_dir=$(dirname "$path")
    
    # Check if path is absolute (starts with /)
    if [[ "$path" != /* ]]; then
        echo "Error: Please enter an absolute path (starting with /)"
        return 1
    fi
    
    # Check if parent directory exists and is accessible
    if [ ! -d "$parent_dir" ]; then
        echo "Error: Invalid path - parent directory '$parent_dir' does not exist"
        return 2
    fi
    
    # Check if directory already exists
    if [ -d "$path" ]; then
        echo "Error: Directory '$path' already exists"
        return 3
    fi
    
    return 0
}

while true; do
    validate_path "$clone_path"
    path_status=$?
    
    if [ $path_status -eq 0 ]; then
        break
    fi
    
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
gh repo clone "$REPO_OWNER/$project_name" "$clone_path"

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
