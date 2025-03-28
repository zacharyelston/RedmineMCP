# Redmine Model Context Protocol (MCP) Extension

A Python-based middleware that enables Large Language Models (LLMs) to create and update issues in Redmine through a structured API interface.

## Overview

This extension allows AI assistants to interact with your Redmine project management system through a Model Context Protocol implementation. It bridges the gap between AI capabilities and Redmine's project tracking functionality, enabling automated issue management.

## Features

- **LLM Integration**: Create, update, and analyze Redmine issues using OpenAI's GPT models
- **Web Interface**: Modern Bootstrap-based dashboard for configuration and monitoring
- **API Endpoints**: RESTful API for programmatic access
- **Rate Limiting**: Built-in protection against API overuse
- **Logging**: Comprehensive audit trail of all AI-performed actions
- **Prompt Templates**: Store and manage reusable prompts for common tasks

## Requirements

- Python 3.8+
- Redmine instance with API access
- OpenAI API key

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/redmine-mcp-extension.git
cd redmine-mcp-extension
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure the application:

   **Option 1: Using credentials.yaml (recommended for development)**
   - Copy the `credentials.yaml.example` file to `credentials.yaml`
   - Edit the file with your actual API keys and connection details:
     ```yaml
     redmine:
       url: "https://your-redmine-instance.example.com"
       api_key: "your_redmine_api_key_here"
     
     openai:
       api_key: "your_openai_api_key_here"
     ```
   - **Important**: The `credentials.yaml` file is excluded from version control by `.gitignore` to prevent accidentally committing sensitive information.

   **Option 2: Using the web interface**
   - Navigate to the settings page in the web interface
   - Enter your Redmine URL and API key
   - Enter your OpenAI API key
   - Set rate limiting parameters
   - You can also save your settings to a credentials.yaml file or load settings from an existing file through the web interface

## Usage

Start the server:
```bash
python main.py
```

The web interface will be available at http://localhost:5000

### API Usage Examples

#### Create a new issue

```python
import requests

response = requests.post(
    'http://localhost:5000/api/llm/create_issue',
    json={
        'prompt': 'Create a bug report for a login page error where users receive 404 error after login attempt'
    }
)
print(response.json())
```

#### Update an existing issue

```python
response = requests.post(
    'http://localhost:5000/api/llm/update_issue/123',
    json={
        'prompt': 'Change the priority to high and assign to John'
    }
)
print(response.json())
```

#### Analyze an issue

```python
response = requests.post(
    'http://localhost:5000/api/llm/analyze_issue/123',
    json={}
)
print(response.json())
```

## Architecture

This extension follows a middleware approach:

1. **Python Flask Application**: Serves as the core middleware
2. **Redmine API Client**: Communicates with Redmine via REST API
3. **OpenAI API Client**: Handles LLM interactions
4. **SQLite/PostgreSQL Database**: Stores configuration, logs, and prompt templates

The application does not modify the Redmine codebase directly, making it compatible with any Redmine instance that has API access enabled.

## Security Considerations

- API keys are stored in the database and should be protected
- If using credentials.yaml, ensure it's properly secured and not exposed in version control
- Rate limiting helps prevent excessive API usage costs
- All LLM actions are logged for audit purposes
- The application should be deployed behind a secure proxy in production

## License

[MIT License](LICENSE)

## Development

### Development Environment

We plan to provide a Docker container with a pre-configured Redmine instance for development and testing purposes. This will allow developers to quickly set up a consistent environment without needing to configure Redmine manually.

Once implemented, you will be able to start the development environment with:

```bash
docker-compose up -d
```

This will start both the Redmine container and the MCP extension, with all necessary connections pre-configured.

### Configuration for Development

For local development, use the `credentials.yaml` file to store your API keys and connection details. The repository includes a `.gitignore` file that prevents this file from being committed to version control, ensuring your sensitive information remains private.

1. Copy `credentials.yaml.example` to `credentials.yaml`
2. Edit with your actual development credentials
3. The application will automatically read from this file when available

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.