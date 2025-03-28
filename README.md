# Redmine Model Context Protocol Extension

A Model Context Protocol (MCP) extension for Redmine that leverages Anthropic's Claude AI to streamline issue management through an intelligent, user-friendly Python-based API.

## Overview

This project implements a middleware service that connects Redmine (a popular project management system) with advanced Large Language Models (specifically Claude) to enable AI-assisted issue management. Instead of directly modifying Redmine's Ruby codebase, this extension operates as a separate service that communicates with Redmine via its REST API.

## Key Features

- **AI-Powered Issue Creation**: Generate well-structured Redmine issues from natural language descriptions
- **Intelligent Issue Updates**: Update existing issues using natural language commands
- **Issue Analysis**: Get AI-powered insights and recommendations for existing issues
- **Web Interface**: Simple dashboard for configuration and monitoring
- **Rate Limiting**: Built-in protection against API overuse
- **Comprehensive Logging**: Detailed logs of all AI operations
- **Docker Integration**: Full Docker support for easy setup and deployment

## Requirements

- Python 3.9+ (for local development)
- Docker and Docker Compose (for containerized setup)
- Anthropic Claude API key

## Installation and Setup

### Option 1: Quick Local Setup

This option provides a simple setup for local development with minimal configuration.

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/redmine-mcp.git
   cd redmine-mcp
   ```

2. Run the local development script:
   ```bash
   chmod +x start_local_dev.sh
   ./start_local_dev.sh
   ```

3. Set up your credentials:
   ```bash
   chmod +x scripts/setup_local_credentials.sh
   ./scripts/setup_local_credentials.sh
   ```
   
4. Follow the on-screen instructions to set up your Redmine API key and Claude API key

The setup includes:
- A Redmine instance at http://localhost:3000 (default login: admin/admin)
- The MCP extension at http://localhost:5000
- SQLite database for Redmine (for simplicity)
- Automatic file volumes for persistent storage

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
- The MCP extension at http://localhost:5000
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

6. Access the web interface at `http://localhost:5000`

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

response = requests.post("http://localhost:5000/api/llm/create_issue", json=payload)
print(response.json())
```

### Update an existing issue

```python
import requests

payload = {
    "prompt": "Change the priority to high and add more information about the browser versions affected"
}

response = requests.post("http://localhost:5000/api/llm/update_issue/123", json=payload)
print(response.json())
```

### Analyze an issue

```python
import requests

response = requests.post("http://localhost:5000/api/llm/analyze_issue/123", json={})
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
- **scripts/setup_docker_dev.sh**: Set up the full Docker development environment
- **scripts/setup_redmine.sh**: Set up a standalone Redmine container
- **scripts/test_mcp_integration.py**: Test the MCP integration functionality
- **scripts/test_redmine_api.sh**: Test the Redmine API connectivity
- **scripts/update_api_urls.sh**: Update API URLs across the codebase
- **scripts/cleanup_dev_env.sh**: Clean up the development environment
- **scripts/cleanup_docker_env.sh**: Clean up Docker containers and volumes
- **scripts/check_github_actions.sh**: Check GitHub Actions build results from Replit

### Development Workflow

1. Start with `./start_local_dev.sh` to set up the environment
2. Configure credentials with `./scripts/setup_local_credentials.sh`
3. Create a feature branch with `./scripts/create_feature_branch.sh feature-name`
4. Make your changes and test with the test suite
5. When done, clean up with `./scripts/cleanup_dev_env.sh`

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