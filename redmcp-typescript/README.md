# Redmine MCP Server (TypeScript)

A modern Model Context Protocol (MCP) server that connects Claude Desktop to Redmine project management system.

## Overview

This server provides a robust interface between Claude and Redmine, allowing for seamless interaction with projects, issues, and users. Built with TypeScript and the official MCP SDK, it offers a type-safe and reliable implementation.

## Features

- **Projects**: List all projects and get detailed information about specific projects
- **Issues**: List, get, create, and update issues in Redmine
- **Users**: Get information about the current authenticated user
- **Robust Error Handling**: Detailed error reporting for troubleshooting
- **Parameter Validation**: Comprehensive validation of all parameters
- **Mock Mode**: Enables development and testing without a Redmine instance

### About Mock Mode

Mock mode is a powerful feature that allows you to develop and test the MCP server without requiring an active Redmine instance. This is particularly useful in the following scenarios:

- **Development Environments**: When building new features without affecting a production Redmine instance
- **Offline Work**: When you need to work without an internet connection
- **Testing**: For consistent and reproducible test environments
- **Demos**: For demonstrations without relying on external services

To enable mock mode, set the `SERVER_MODE` environment variable to `mock` in your `.env` file:
```
SERVER_MODE=mock
```

The mock data provider simulates all Redmine operations with consistent, predictable responses.

## Requirements

- Node.js 18 or higher
- npm or yarn
- Redmine instance with API access

## Installation

### Local Development

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd redmcp-typescript
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file with your Redmine configuration:
   ```
   REDMINE_URL=http://your-redmine-instance.com
   REDMINE_API_KEY=your-api-key-here
   LOG_LEVEL=info
   ```

4. Build the TypeScript code:
   ```bash
   npm run build
   ```

5. Start the server:
   ```bash
   npm start
   ```

## Code Standards

### File Structure
The codebase follows a modular architecture to ensure maintainability and separation of concerns:

- `src/client/`: API client modules for Redmine resources (issues, projects, etc.)
- `src/core/`: Core functionality (error handling, logging, server setup)
- `src/lib/`: Utility libraries and implementations (RedmineClient, mock data)
- `src/tools/`: MCP tools implementation (connects API clients to MCP)
- `src/types/`: TypeScript type definitions

### TypeScript File Headers
All TypeScript files must include a standardized header format that describes the file's purpose:

```typescript
/**
 * [Module Name]
 * 
 * [Brief description of what the module does]
 */
```

This header should be 5 lines or less and provide a clear indication of the file's purpose and functionality.

### Error Handling
All operations must include robust error handling through:
1. Consistent parameter validation
2. Structured logging to `todo.yaml` 
3. Detailed error messages with context
4. Verification of critical operations

## Integrating with Claude Desktop

To use this MCP server with Claude Desktop, add the following configuration to Claude Desktop's configuration file:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "redmine": {
      "command": "node",
      "args": ["/absolute/path/to/redmcp-typescript/build/index.js"],
      "env": {
        "REDMINE_URL": "http://your-redmine-instance.com",
        "REDMINE_API_KEY": "your-api-key-here",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

## Available Tools

### Projects

- **redmine_projects_list**: List all accessible Redmine projects
  - Parameters:
    - `limit` (optional, default: 25): Number of projects to return
    - `offset` (optional, default: 0): Pagination offset
    - `sort` (optional, default: 'name:asc'): Field to sort by with direction

- **redmine_projects_get**: Get details of a specific Redmine project
  - Parameters:
    - `identifier` (required): Project identifier
    - `include` (optional): Related data to include (e.g. trackers, issue_categories)

### Issues

- **redmine_issues_list**: List issues with optional filtering
  - Parameters:
    - `project_id` (optional): Filter by project identifier
    - `status_id` (optional): Filter by status
    - `tracker_id` (optional): Filter by tracker
    - `limit` (optional, default: 25): Number of issues to return
    - `offset` (optional, default: 0): Pagination offset
    - `sort` (optional, default: 'updated_on:desc'): Field to sort by with direction

- **redmine_issues_get**: Get details of a specific issue
  - Parameters:
    - `issue_id` (required): Issue ID
    - `include` (optional): Related data to include

- **redmine_issues_create**: Create a new issue
  - Parameters:
    - `project_id` (required): Project ID
    - `subject` (required): Issue subject
    - `description` (optional): Issue description
    - `tracker_id` (optional): Tracker ID
    - `status_id` (optional): Status ID
    - `priority_id` (required): Priority ID
    - `assigned_to_id` (optional): Assignee ID

- **redmine_issues_update**: Update an existing issue
  - Parameters:
    - `issue_id` (required): Issue ID
    - `subject` (optional): New issue subject
    - `description` (optional): New issue description
    - `status_id` (optional): New status ID
    - `priority_id` (optional): New priority ID
    - `assigned_to_id` (optional): New assignee ID

### Users

- **redmine_users_current**: Get information about the current user
  - No parameters

## Configuration

### Environment Variables

- `REDMINE_URL`: URL of the Redmine instance (default: http://localhost:3000)
- `REDMINE_API_KEY`: API key for Redmine authentication
- `SERVER_MODE`: Server operation mode (options: 'live', 'mock', default: 'live')
- `LOG_LEVEL`: Logging level (options: 'debug', 'info', 'error', default: 'info')

## Troubleshooting

For detailed troubleshooting steps and solutions, see the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) file.

Common issues and quick solutions:

- Check the Claude Desktop logs for any errors. On macOS, logs are located at `~/Library/Logs/Claude/`.
- Ensure your Redmine instance is accessible and the API key has appropriate permissions.
- If the server isn't connecting, verify that the path in the Claude Desktop configuration is correct.
- When creating issues, ensure the priority_id field is included (required by Redmine).

## Future Development

See [TODO.md](./TODO.md) for planned enhancements and future development.

## License

MIT
