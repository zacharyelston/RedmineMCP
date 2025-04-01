# Development Scripts

This directory contains scripts that help streamline the development workflow for the Redmine MCP Extension.

## Unified Scripts (New)

We've consolidated many scripts to simplify development workflows:

### `setup.py`

All-in-one setup script for the Redmine MCP Extension.

```bash
# Set up credentials
python scripts/setup.py credentials [--redmine-url URL] [--redmine-api-key KEY] [--claude-api-key KEY] [--openai-api-key KEY] [--llm-provider {claude,openai}] [--rate-limit LIMIT] [--force]

# Validate configuration
python scripts/setup.py validate

# Set up local development environment
python scripts/setup.py dev

# Set up Docker development environment
python scripts/setup.py docker [--build]
```

### `test_api.py`

Unified API testing script for Redmine, Claude, and OpenAI.

```bash
# Test Redmine API
python scripts/test_api.py redmine [--verbose] [--create-issue]

# Test Claude API
python scripts/test_api.py claude [--verbose]

# Test OpenAI API
python scripts/test_api.py openai [--verbose]

# Test all APIs
python scripts/test_api.py all [--verbose]
```

### `test_mcp.py`

Unified MCP integration testing script.

```bash
# Test all MCP functionality
python scripts/test_mcp.py --base-url=http://localhost:9000 [--all]

# Test specific MCP endpoints
python scripts/test_mcp.py --capabilities --health
python scripts/test_mcp.py --create --project-id=1
python scripts/test_mcp.py --update=123 --analyze=123
```

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

## Legacy Scripts (Consider using the unified scripts above instead)

### `validate_configs.py`

Validates configuration files to catch common errors before they reach CI/CD.

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

### `test_mcp_integration.py`

Tests the MCP integration functionality.

### `test_redmine_api.sh` and `test_redmine_api.py`

Tests the Redmine API connectivity.

### `test_claude_api.py`

Tests the Claude API connectivity.

## CI/CD Scripts

### `check_github_actions.sh`

Checks GitHub Actions build results from Replit.

```bash
./check_github_actions.sh <github-username> redmine-mcp-extension [workflow-name]
```