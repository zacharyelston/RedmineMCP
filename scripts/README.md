# Development Scripts

This directory contains scripts that help streamline the development workflow for the Redmine MCP Extension.

## Git Workflow Scripts

### `create_feature_branch.sh`

Creates a new feature branch from the latest main branch.

```bash
./create_feature_branch.sh
```

- Prompts for branch name
- Creates the branch with prefix `feature/`
- Checks out the new branch

### `commit_to_fix_branch.sh`

Commits changes to a fix or feature branch.

```bash
./commit_to_fix_branch.sh
```

- Validates configuration files using `validate_configs.py`
- Prompts for branch type (fix/ or feature/)
- Prompts for branch name and commit message
- Creates the branch or uses existing branch
- Commits changes

## Validation Scripts

### `validate_configs.py`

Validates configuration files to catch common errors before they reach CI/CD.

```bash
python validate_configs.py
```

Checks:
- TOML files (like pyproject.toml) for duplicate declarations
- Python files (like setup.py) for syntax errors
- YAML files (like docker-compose.yml) for syntax errors

Returns exit code 0 if all checks pass, 1 if any check fails.

## Docker and Environment Setup

### `setup_docker_dev.sh`

Sets up the full Docker development environment.

### `setup_local_credentials.sh`

Guides you through setting up API credentials.

### `setup_redmine.sh`

Sets up a standalone Redmine container.

### `cleanup_dev_env.sh`

Cleans up the development environment.

### `cleanup_docker_env.sh`

Cleans up Docker containers and volumes.

## Testing Scripts

### `test_mcp_integration.py`

Tests the MCP integration functionality.

### `test_redmine_api.sh`

Tests the Redmine API connectivity.

## CI/CD Scripts

### `check_github_actions.sh`

Checks GitHub Actions build results from Replit.

```bash
./check_github_actions.sh <github-username> redmine-mcp-extension [workflow-name]
```