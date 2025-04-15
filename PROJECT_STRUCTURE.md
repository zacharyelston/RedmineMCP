# Redmine MCP Project Structure

This document provides an overview of the Redmine MCP project structure and its components.

## Project Overview

The Redmine MCP project enables Claude AI to interact with Redmine project management systems through the Model Context Protocol (MCP). The project consists of multiple components working together to provide a seamless integration experience.

## Directory Structure

```
redmine-mcp/
├── docs/                # Project documentation
│   ├── architecture/    # Architecture diagrams and documentation
│   └── integration/     # Integration guides
├── prompt.yaml          # MCP protocol configuration and tool definitions
├── redmcp-typescript/   # TypeScript implementation of the MCP server
│   ├── src/             # Source code
│   │   ├── index.ts     # Main server entry point
│   │   └── lib/         # Library code and utilities
│   ├── docs/            # Implementation-specific documentation
│   ├── .env             # Environment configuration
│   └── README.md        # TypeScript implementation documentation
├── redmine-server/      # Development environment
│   ├── docker-compose.yml    # Docker configuration
│   ├── config/          # Redmine configuration
│   └── data/            # Database initialization scripts
└── README.md            # Main project documentation
```

## Key Components

### TypeScript MCP Server (`redmcp-typescript/`)

The core of the project is the TypeScript implementation of the MCP server. This server:

1. Implements the Model Context Protocol (MCP) specification
2. Connects to Redmine API using authentication
3. Handles Claude's requests and translates them to Redmine operations
4. Provides robust error handling and parameter validation

The TypeScript implementation is modern, maintainable, and offers type-safety throughout the codebase.

### Redmine Development Environment (`redmine-server/`)

A Docker-based development environment that provides:

1. A fully configured Redmine instance
2. PostgreSQL database with sample data
3. Predefined users with API keys
4. Network configuration for local development

This environment allows for testing the MCP server without requiring an external Redmine instance.

### MCP Protocol Configuration (`prompt.yaml`)

The `prompt.yaml` file defines:

1. Available MCP tools that Claude can use
2. Command structures and parameters
3. Examples of how to use the tools
4. Command whitelist for security purposes

This file serves as both documentation and configuration for the MCP protocol implementation.

## Component Interactions

1. **Claude Desktop** connects to the **TypeScript MCP Server** using the configuration specified in Claude Desktop's settings
2. The **TypeScript MCP Server** processes Claude's requests and communicates with the **Redmine API**
3. **Redmine API** performs the requested operations and returns results to the MCP server
4. The MCP server formats the responses according to the MCP protocol and sends them back to Claude

## Authentication Flow

1. Redmine API key is stored in the `.env` file of the TypeScript implementation
2. The MCP server uses this key for all API requests to Redmine
3. All operations are performed with the permissions of the user associated with the API key

## Development Workflow

1. Start the Redmine development environment (`docker-compose up -d` in `redmine-server/`)
2. Build and start the TypeScript MCP server (`npm build && npm start` in `redmcp-typescript/`)
3. Configure Claude Desktop to connect to the MCP server
4. Test the integration by asking Claude to perform Redmine operations

## Deployment Considerations

For production deployment, consider:

1. Using a secure, production Redmine instance with HTTPS
2. Configuring proper API keys with appropriate permissions
3. Setting up logging and monitoring for the MCP server
4. Regularly updating dependencies for security
5. Implementing proper error handling and recovery mechanisms

## Troubleshooting

When issues arise:

1. Check Claude Desktop logs for MCP communication errors
2. Review the MCP server logs for API errors
3. Verify Redmine API connectivity and permissions
4. Consult the troubleshooting guide in `redmcp-typescript/TROUBLESHOOTING.md`
