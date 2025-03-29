# Redmine Model Context Protocol Extension

A Model Context Protocol (MCP) extension for Redmine that leverages Large Language Models (Claude and OpenAI) to streamline issue management through an intelligent, user-friendly Python-based API. Supports both x86/x64 and ARM64 architectures.

## Overview

This project implements a middleware service that connects Redmine (a popular project management system) with advanced Large Language Models to enable AI-assisted issue management. Instead of directly modifying Redmine's Ruby codebase, this extension operates as a separate service that communicates with Redmine via its REST API.

The extension supports multiple LLM providers (Claude and OpenAI) and runs on both x86 and ARM64 architectures, making it compatible with a wide range of development and deployment environments.

## Key Features

- **AI-Powered Issue Creation**: Generate well-structured Redmine issues from natural language descriptions
- **Intelligent Issue Updates**: Update existing issues using natural language commands
- **Issue Analysis**: Get AI-powered insights and recommendations for existing issues
- **Cross-Platform**: Compatible with both x86 and ARM64 architectures
- **Web Interface**: Simple dashboard for configuration and monitoring
- **Rate Limiting**: Built-in protection against API overuse
- **Comprehensive Logging**: Detailed logs of all AI operations
- **Docker Integration**: Full Docker support for easy setup and deployment
- **Resilience**: Graceful handling of Redmine unavailability with offline testing mode

## Requirements

- Python 3.9+ (for local development)
- Docker and Docker Compose (for containerized setup)
- Works on x86/x64 and ARM64 architectures (Apple Silicon M1/M2/M3, AWS Graviton, etc.)
  - Special handling for ARM64-specific Docker issues like 'ContainerConfig' KeyError

## Installation and Setup

### Option 1: Quick Local Setup

This option provides a simple setup for local development with minimal configuration.

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/redmine-mcp.git
   cd redmine-mcp
   ```

2. Set up a local Redmine instance and auto-generate API key:
   ```bash
   chmod +x scripts/setup_redmine.sh
   ./scripts/setup_redmine.sh
   ```
   
   This script will:
   - Start a Redmine Docker container
   - Generate a random API key
   - Configure Redmine to use this API key
   - Create a credentials.yaml file with this key
   - Enable the REST API in Redmine settings

3. Start the MCP extension:
   ```bash
   chmod +x start_local_dev.sh
   ./start_local_dev.sh
   ```

4. Add your Claude API key to the credentials.yaml file (only required for LLM functionality)

The setup includes:
- A Redmine instance at http://localhost:3000 (default login: admin/admin)
- The MCP extension at http://localhost:9000
- SQLite database for Redmine (for simplicity)
- Automatic file volumes for persistent storage
- Pre-configured API key that works out of the box

### Option 2: Full Docker Setup (Recommended for MCP Integration)

This option sets up both Redmine and the MCP extension in Docker containers, providing a complete environment for development and testing with more advanced configuration.

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/redmine-mcp.git
   cd redmine-mcp
   ```

2. Run the setup script to configure the Docker environment:
   ```bash
   chmod +x scripts/setup_docker_dev.sh
   ./scripts/setup_docker_dev.sh
   ```

3. Edit the `.env` file to add your Claude API key.

4. Start the entire stack:
   ```bash
   ./start_mcp_dev.sh
   ```

The setup includes:
- A Redmine instance at http://localhost:3000 (admin/admin)
- The MCP extension at http://localhost:9000
- Automatic configuration of Redmine API access
- A sample project for testing
- PostgreSQL database for Redmine (for production-like environment)

### Option 3: Local Installation (No Docker)

For standalone development without Docker (requires an existing Redmine instance):

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/redmine-mcp.git
   cd redmine-mcp
   ```

2. Install required dependencies:
   ```
   pip install -e .
   ```

3. Create configuration:
   ```
   cp credentials.yaml.example credentials.yaml
   ```
   
4. Edit `credentials.yaml` with your actual Redmine URL, API key, and Claude API key.

5. Start the application:
   ```
   python main.py
   ```

6. Access the web interface at `http://localhost:9000`

## MCP Integration

The extension implements the Model Context Protocol for seamless integration with MCP clients:

1. The API endpoints are already MCP-compatible
2. Use the Docker setup for proper connection to your MCP environment
3. The extension will appear in your MCP client once properly connected

### Claude Desktop Integration

The project includes a `desktop_config.json` file that enables easy integration with Claude Desktop:

1. Make sure Claude Desktop is installed on your machine
2. Configure Claude Desktop to use the configuration file:
   ```
   claude config import ./desktop_config.json
   ```
3. Select the "dev" profile from Claude Desktop
4. This will automatically start both Redmine and the MCP Extension
5. Follow the instructions to set up your API keys

## Usage

Use the API endpoints to interact with the extension:
- `/api/llm/create_issue` - Create a new issue
- `/api/llm/update_issue/{issue_id}` - Update an existing issue
- `/api/llm/analyze_issue/{issue_id}` - Analyze an issue

## API Usage Examples

### Create a new issue

```python
import requests

payload = {
    "prompt": "Create a bug report for a login page issue where users are experiencing 404 errors after submitting login credentials on the production environment"
}

response = requests.post("http://localhost:9000/api/llm/create_issue", json=payload)
print(response.json())
```

### Update an existing issue

```python
import requests

payload = {
    "prompt": "Change the priority to high and add more information about the browser versions affected"
}

response = requests.post("http://localhost:9000/api/llm/update_issue/123", json=payload)
print(response.json())
```

### Analyze an issue

```python
import requests

response = requests.post("http://localhost:9000/api/llm/analyze_issue/123", json={})
print(response.json())
```

## Testing

To run the tests:

```
pytest
```

To run specific test files:

```
pytest tests/test_redmine_api.py
pytest tests/test_llm_api.py
```

## Development

### Development Scripts

The project includes several helper scripts to streamline development:

- **start_local_dev.sh**: Quick start for local development with Docker
- **scripts/setup_local_credentials.sh**: Easily set up and configure API credentials
- **scripts/create_feature_branch.sh**: Create a new git feature branch
- **scripts/commit_to_fix_branch.sh**: Commit changes to a fix or feature branch
- **scripts/validate_configs.py**: Validate configuration files before committing
- **scripts/setup_docker_dev.sh**: Set up the full Docker development environment
- **scripts/setup_redmine.sh**: Set up a standalone Redmine container (improved for ARM64)
- **scripts/test_mcp_integration.py**: Test the MCP integration functionality
- **scripts/test_redmine_api.sh**: Test the Redmine API connectivity
- **scripts/test_redmine_availability.py**: Test MCP robustness with unavailable Redmine
- **scripts/test_redmine_api_functionality.py**: Comprehensive test for Redmine API functionality
- **scripts/validate_redmine_api.sh**: Easy-to-use wrapper for the Redmine API test script
- **scripts/test_openai_api.py**: Test OpenAI API integration
- **scripts/test_claude_api.py**: Test Claude API integration
- **scripts/check_docker_compatibility.sh**: Diagnose Docker setup and compatibility
- **scripts/test_mcp_robustness.sh**: Test overall robustness (Docker + service availability)
- **scripts/update_api_urls.sh**: Update API URLs across the codebase
- **scripts/cleanup_dev_env.sh**: Clean up the development environment
- **scripts/cleanup_docker_env.sh**: Clean up Docker containers and volumes
- **scripts/check_github_actions.sh**: Check GitHub Actions build results from Replit

### Development Workflow

1. Setup a local Redmine instance with auto-generated API key:
   ```bash
   ./scripts/setup_redmine.sh
   ```

2. Start the MCP extension:
   ```bash
   ./start_local_dev.sh
   ```

3. Create a feature branch for your changes:
   ```bash
   ./scripts/create_feature_branch.sh feature-name
   ```

4. Make your changes and test with the test suite:
   ```bash
   pytest
   ```

5. When ready to commit, use the automated commit script which includes validation:
   ```bash
   ./scripts/commit_to_fix_branch.sh
   ```
   This will automatically validate configuration files before committing
   
6. Push your changes to GitHub:
   ```bash
   git push origin your-branch-name
   ```

7. When done with development, clean up the environment:
   ```bash
   ./scripts/cleanup_dev_env.sh
   ```

#### Preventing Common Configuration Errors

To prevent configuration errors that could lead to CI/CD failures:

```bash
# Validate all configuration files before committing
python scripts/validate_configs.py

# Commit changes with automatic validation
./scripts/commit_to_fix_branch.sh
```

The validation script checks for:
- Duplicate declarations in TOML files
- Syntax errors in Python, YAML, and TOML files
- Common package configuration issues

This helps catch issues before they reach GitHub Actions.

#### Testing MCP Robustness

The MCP extension is designed to be resilient to common failure scenarios, including temporary Redmine unavailability or API errors. This helps development teams continue working even when the full system isn't available:

1. **Offline Operation Testing**: Test how the MCP extension handles situations where Redmine is unavailable:
   ```bash
   ./scripts/test_redmine_availability.py --create-test-config
   # Test functionality while Redmine is "offline"
   ./scripts/test_redmine_availability.py --restore-config
   ```

2. **Docker Compatibility Testing**: Verify Docker configuration and diagnose issues:
   ```bash
   ./scripts/check_docker_compatibility.sh
   ```

3. **Complete Robustness Test**: Run a full suite of tests against common failure modes:
   ```bash
   ./scripts/test_mcp_robustness.sh
   ```

4. **Health Endpoint**: The `/api/health` endpoint provides detailed status information about all services:
   ```bash
   curl http://localhost:9000/api/health | jq
   ```
   
   The health endpoint will show different statuses for Redmine availability:
   - `healthy`: Redmine is available and API is accessible
   - `unavailable`: Redmine web server is not responding
   - `api_error`: Redmine is running but API access is failing
   - `unknown`: Status could not be determined

5. **Comprehensive Redmine API Testing**: Test the full functionality of your Redmine instance with the validation script:
   ```bash
   # Using the simple wrapper script
   ./scripts/validate_redmine_api.sh
   
   # With custom options
   ./scripts/validate_redmine_api.sh --redmine-url=http://localhost:3000 --cleanup
   
   # Using the Python script directly
   python scripts/test_redmine_api_functionality.py --redmine-url=http://localhost:3000
   ```
   
   This script performs a comprehensive test of the Redmine API, including:
   - Creating test projects, issues, versions, and wiki pages
   - Updating issues with different statuses
   - Retrieving and validating reference data (trackers, statuses, priorities)
   - Cleaning up all test resources after completion (with the `--cleanup` flag)
   
   It's ideal for validating that your Redmine API key is working correctly and that all required API endpoints are available.

#### ARM64 Compatibility (Apple Silicon / AWS Graviton)

If you're using an ARM64-based machine (such as Apple Silicon M1/M2/M3 Macs or AWS Graviton instances), the following accommodations are included:

1. **MariaDB Instead of MySQL**: All scripts use MariaDB containers rather than MySQL for improved ARM64 compatibility.

2. **Container Recreation Fixes**: To avoid the 'ContainerConfig' KeyError issue that occurs on ARM64 platforms:
   ```bash
   # Problem: Error when recreating containers with volumes on ARM64
   KeyError: 'ContainerConfig'
   
   # Solution - Before starting containers:
   docker-compose -f your-compose-file.yml down -v
   docker rm -f container-name 2>/dev/null || true
   
   # Then start with --force-recreate:
   docker-compose -f your-compose-file.yml up -d --force-recreate
   ```
   
3. **ARM64 Testing Script**: Use `scripts/test_arm64_compat.sh` to verify compatibility:
   ```bash
   ./scripts/test_arm64_compat.sh
   ```
   
4. **GitHub Actions**: CI/CD workflows support ARM64 through MariaDB usage

### Testing Redmine Frontend

The project includes several options for testing with the Redmine frontend:

#### Option 1: Quick Local Docker Setup
```bash
./start_local_dev.sh
```
This will start Redmine at http://localhost:3000 with admin/admin credentials.

#### Option 2: Standalone Redmine Container
```bash
./scripts/setup_redmine.sh
```
This will start only the Redmine container for testing the API.

#### Option 3: Claude Desktop Integration
```bash
# Import the desktop configuration
claude config import ./desktop_config.json

# Start using the dev profile
claude start dev
```
This will start both Redmine and the MCP Extension through the Claude Desktop interface.

### Checking GitHub Actions Build Results

You can check the status of your GitHub Actions builds directly from Replit using the provided script:

```bash
# List all recent workflow runs
./scripts/check_github_actions.sh <your-github-username> redmine-mcp-extension

# Check a specific workflow
./scripts/check_github_actions.sh <your-github-username> redmine-mcp-extension "Claude API Test"
```

Requirements:
- GitHub CLI (`gh`) must be installed (see `scripts/README_GITHUB_CLI.md` for installation guide)
- You must be authenticated with GitHub CLI (`gh auth login`)

This provides a convenient way to monitor your CI/CD pipeline without leaving Replit.

#### Troubleshooting GitHub Actions Builds

If you encounter build failures with packages not being installed correctly (like "Multiple top-level packages discovered in a flat-layout"), here are some solutions:

1. The project includes a `pyproject.toml` and `setup.py` that define the package structure
2. These files explicitly exclude non-package directories like `static` and `templates`
3. Make sure your workflow uses `pip install -e .` to install the package in development mode
4. For complete dependency installation, refer to the workflow files in `.github/workflows/`

## License

MIT