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

### Option 1: Docker Setup (Recommended for MCP Integration)

This option sets up both Redmine and the MCP extension in Docker containers, providing a complete environment for development and testing.

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

### Option 2: Local Installation

For standalone development without Docker:

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

- Use the included scripts in the `scripts` directory for development tasks
- Create new feature branches using `scripts/create_feature_branch.sh`
- Test your changes using the provided test suite

## License

MIT