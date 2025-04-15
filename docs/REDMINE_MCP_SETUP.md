# Redmine MCP Server Setup Guide

## Overview

This document provides comprehensive instructions for setting up the Redmine MCP (ModelContextProtocol) environment. The MCP server allows for standardized interactions with Redmine through a protocol-based approach.

## Prerequisites

- Docker and Docker Compose installed
- Basic familiarity with command-line operations
- No other applications running on ports 3000 (Redmine) and 5432 (PostgreSQL)

## Quick Start

For a complete automated setup, run:

```bash
bash /redmine-mcp/scripts/bootstrap-redmine-mcp.sh
```

This script:
1. Prepares the environment
2. Updates configurations
3. Starts Redmine server
4. Starts MCP server
5. Verifies connectivity between services

## Manual Setup Instructions

If you prefer to set up the environment manually, follow these steps:

### 1. Start Redmine Server

```bash
cd /redmine-mcp/redmine-server
docker-compose up -d
```

Wait for Redmine to initialize (typically 30-60 seconds).

### 2. Configure MCP Server

Edit `/redmine-mcp/mcp-server/config/config.json`:

```json
{
  "redmine_url": "http://localhost:3000",
  "redmine_api_key": "your-redmine-api-key",
  "log_level": "info",
  "mcp_version": "1.0"
}
```

### 3. Start MCP Server

```bash
cd /redmine-mcp/mcp-server
docker-compose up -d
```

## Troubleshooting Connection Issues

If the MCP server cannot connect to Redmine, try these solutions:

### Solution 1: Use host.docker.internal

Edit the MCP server configuration to use Docker's special DNS name:

```json
{
  "redmine_url": "http://host.docker.internal:3000",
  "redmine_api_key": "your-redmine-api-key",
  "log_level": "info",
  "mcp_version": "1.0"
}
```

Restart the MCP server:

```bash
cd /redmine-mcp/mcp-server
docker-compose restart
```

### Solution 2: Create a Common Docker Network

1. Create a shared network:
   ```bash
   docker network create redmine-mcp-network
   ```

2. Update both docker-compose files to use this network
   (See documentation for detailed instructions)

## Obtaining a Redmine API Key

1. Access Redmine at http://localhost:3000
2. Log in with default credentials (admin/admin)
3. Go to My Account > API access key
4. Click "Show" to view your API key or "Generate" to create a new one
5. Copy this key to your MCP server configuration

## MCP Protocol Guidelines

When working with the MCP server, remember these best practices:

1. Work on one task at a time and validate before moving on
2. Process is the key - follow standard procedures for each operation
3. Document all changes and verify they work before proceeding
4. Maintain version control of configuration files
5. Test thoroughly after any configuration changes

## Backup and Recovery

To backup the Redmine data:

```bash
cd /redmine-mcp/redmine-server
docker-compose exec postgres pg_dump -U redmine redmine > redmine_backup.sql
```

To restore from backup:

```bash
cd /redmine-mcp/redmine-server
cat redmine_backup.sql | docker-compose exec -T postgres psql -U redmine redmine
```

## Next Steps

After successful setup:
1. Create projects in Redmine
2. Set up user accounts and permissions
3. Configure project workflows
4. Start using the MCP protocol to interact with Redmine

## Support and Additional Resources

For more information:
- Check the project documentation in `/redmine-mcp/docs`
- Review the MCP protocol specifications
- Consult the Redmine official documentation at https://www.redmine.org/guide
