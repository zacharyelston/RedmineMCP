# GitHub CLI Setup for Redmine MCP Extension

The `check_github_actions.sh` script requires GitHub CLI (`gh`) to be installed on your system.

## Installation Instructions

### Linux
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Fedora/CentOS/RHEL
sudo dnf install gh

# Arch Linux
sudo pacman -S github-cli
```

### macOS
```bash
# Using Homebrew
brew install gh

# Using MacPorts
port install gh
```

### Windows
```bash
# Using Scoop
scoop install gh

# Using Chocolatey
choco install gh
```

## Authentication

Once installed, you need to authenticate with GitHub:

```bash
gh auth login
```

Follow the interactive prompts to complete the authentication process. You can choose:
- GitHub.com or GitHub Enterprise
- HTTPS or SSH protocol
- Authenticate with browser or token

## Testing Installation

To verify the installation and authentication:

```bash
gh auth status
```

This should show that you're authenticated and connected to your GitHub account.

## Using with Redmine MCP Extension

Once GitHub CLI is set up, you can use the `check_github_actions.sh` script:

```bash
./scripts/check_github_actions.sh <your-github-username> redmine-mcp-extension
```

This will show the status of recent GitHub Actions workflow runs for your repository.

## More Information

For more details about GitHub CLI, visit:
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub CLI Repository](https://github.com/cli/cli)