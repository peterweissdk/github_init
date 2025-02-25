# 💾 GitHub Init

[![Static Badge](https://img.shields.io/badge/Linux-white?style=flat&logo=linux&logoColor=white&logoSize=auto&labelColor=black)](https://www.linux.org/)
[![Static Badge](https://img.shields.io/badge/Bash-Script-white?style=flat&logo=gnubash&logoColor=white&logoSize=auto&labelColor=black)](https://www.gnu.org/software/bash/)
[![Static Badge](https://img.shields.io/badge/Git-white?style=flat&logo=git&logoColor=white&logoSize=auto&labelColor=black)](https://git-scm.com/)
[![Static Badge](https://img.shields.io/badge/GitHub-white?style=flat&logo=github&logoColor=white&logoSize=auto&labelColor=black)](https://github.com/)
[![Static Badge](https://img.shields.io/badge/GPL-V3-white?style=flat&logo=gnu&logoColor=white&logoSize=auto&labelColor=black)](https://www.gnu.org/licenses/gpl-3.0.en.html/)

A bash script to automate the process of creating and initializing GitHub repositories. This script streamlines the workflow of setting up new GitHub projects by handling both local and remote repository creation.

## ✨ Features

- Create new GitHub repositories
- Initialize local Git repositories
- Set up SSH keys for GitHub authentication
- Configure Git user information
- Link local and remote repositories
- Installation option for system-wide availability

## 🚀 Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/peterweissdk/github_init.git
   ```

2. Make the script executable:
   ```bash
   chmod +x github_init.sh
   ```

3. Run the script:
   ```bash
   ./github_init.sh
   ```

4. Optional: Install the script system-wide:
   ```bash
   ./github_init.sh --install
   ```

### Usage Options
- `-i, --install`: Install the script system-wide
- `-u, --update-version`: Update the script version
- `-v, --version`: Display current version
- `-h, --help`: Show help message

## 📝 Directory Structure

```bash
github_init/
├── .git
├── LICENSE
├── README.md
└── github_init.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🆘 Support

If you encounter any issues or need support, please file an issue on the GitHub repository.

## 📄 License

This project is licensed under the GNU GENERAL PUBLIC LICENSE v3.0 - see the [LICENSE](LICENSE) file for details.
