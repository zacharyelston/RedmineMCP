# Redmine MCP Extension

A sophisticated Model Context Protocol (MCP) extension for Redmine that revolutionizes issue management through intelligent AI-driven automation and intuitive user interactions.

## Overview

This extension provides a bridge between Claude Desktop and Redmine, allowing Claude to:
- Create issues with natural language prompts
- Update existing issues
- Analyze issues and provide insights
- Access and manipulate all Redmine resources through a comprehensive API

## Requirements

- Docker
- Claude Desktop with MCP support
- Redmine instance (with API access)

## Setup and Deployment

### 1. Configuration

Copy the example credentials file and update with your Redmine settings:

```bash
cp credentials.yaml.example credentials.yaml
```

Edit `credentials.yaml` with your Redmine URL and API key:

```yaml
redmine_url: 'https://your-redmine-instance.com'
redmine_api_key: 'your-redmine-api-key'
```

### 2. Build Docker Image

Run the build script to create the Docker image:

```bash
chmod +x build-mcp.sh
./build-mcp.sh
```

This will create a local Docker image named `redmine-mcp-extension:latest`. The build script handles all the necessary steps to package the application as a Docker container.

### 3. Configure Claude Desktop MCP

Add the Redmine MCP extension to your Claude Desktop MCP configuration file. Here's an example configuration entry:

```json
{
  "mcps": {
    "redmine": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "REDMINE_API_KEY",
        "-e",
        "REDMINE_URL",
        "redmine-mcp-extension:latest"
      ],
      "environment": {
        "REDMINE_API_KEY": "your-redmine-api-key",
        "REDMINE_URL": "https://your-redmine-instance.com"
      }
    }
  }
}
```

### 4. Using the Extension

Once configured, Claude Desktop will be able to:

- Create Redmine issues by asking Claude to "create a new ticket for..." or similar prompts
- Update issues by referencing their ID: "update issue #123 with..."
- Analyze issues: "analyze issue #456 for complexity and risks"

## Features

- **Issue Management**: Create, update, retrieve, and analyze Redmine issues
- **Project Management**: Access project data, memberships, and versions
- **User Management**: Manage users, roles, and permissions
- **Time Tracking**: Record and retrieve time entries
- **Wiki Integration**: Access and update Wiki pages
- **File Attachments**: Upload and attach files to issues

## API Documentation

### Redmine API

All Redmine REST API endpoints are implemented in the `redmine_api.py` module. The API wrapper provides comprehensive access to:

- Issues API
- Projects API
- Users API
- Time Entries API
- Project Memberships API
- Wiki Pages API
- Project Versions API
- Issue Relations API
- Issue Attachments API

### MCP Endpoints

The MCP extension provides the following endpoints:

- `GET /mcp/`: Returns MCP capabilities
- `GET /mcp/health`: Returns health status of the MCP service
- `POST /mcp/llm/create_issue`: Create a Redmine issue using LLM
- `POST /mcp/llm/update_issue/{issue_id}`: Update a specific Redmine issue using LLM
- `POST /mcp/llm/analyze_issue/{issue_id}`: Analyze a specific Redmine issue using LLM

## Development

The application uses a file-based configuration system with settings stored in:

- `credentials.yaml`: Contains sensitive information (API keys)
- `manifest.yaml`: Contains application metadata and default configurations

### Test Mode

The application supports a test mode that simulates Redmine and LLM functionality without requiring actual connections to these services. This is useful for development and testing.

To enable test mode:

1. Set the Redmine URL in `credentials.yaml` to include the domain `test-redmine-instance.local`:
   ```yaml
   redmine_url: 'http://test-redmine-instance.local:3000'
   ```

2. Set the LLM provider to `mock`:
   ```yaml
   llm_provider: 'mock'
   ```

In test mode:
- Health checks will report all systems as healthy
- Create issue calls will return simulated successful responses
- Update and analyze calls will process without requiring a real Redmine connection

## Troubleshooting

### Common Issues

1. **Docker Image Build Fails**
   - Ensure Docker is installed and running
   - Check if you have sufficient permissions to build Docker images
   - Verify that all required files are present in the root directory

2. **Claude Desktop Cannot Connect to the MCP**
   - Verify the Docker image name in your MCP configuration matches the built image (`redmine-mcp-extension:latest`)
   - Ensure Claude Desktop has been restarted after updating the MCP configuration
   - Check if Docker is running and the image exists (run `docker images` to verify)

3. **Cannot Connect to Redmine**
   - Verify your Redmine URL is correct and accessible from your machine
   - Check that your API key is valid and has sufficient permissions
   - Ensure the Redmine instance supports API access (enabled in settings)

4. **API Rate Limiting Issues**
   - Adjust the `rate_limit_per_minute` value in your credentials.yaml if you're experiencing throttling
   - Consider implementing request caching for frequently accessed resources

### Checking MCP Logs

To view logs from the Docker container:

```bash
docker logs $(docker ps | grep redmine-mcp-extension | awk '{print $1}')
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.