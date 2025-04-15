# Redmine Server Setup Guide

## Overview

This guide provides instructions for setting up the Redmine server to work with the MCP (ModelContextProtocol) system. The focus is solely on getting Redmine running properly so it can be accessed by the claude-desktop MCP client.

## Prerequisites

- Docker and Docker Compose installed
- No other applications using port 3000 (Redmine) or 5432 (PostgreSQL)

## Quick Start

For a complete automated setup of the Redmine server:

```bash
bash /redmine-mcp/scripts/bootstrap-redmine-only.sh
```

This script:
1. Cleans up any existing conflicting containers
2. Prepares SQL migration directories
3. Starts the Redmine server
4. Verifies Redmine is accessible

## Manual Setup Instructions

If you prefer to set up Redmine manually:

### 1. Prepare Environment

```bash
# Create necessary directories
mkdir -p /redmine-mcp/redmine-server/sql/migrations
mkdir -p /redmine-mcp/redmine-server/sql/callbacks
```

### 2. Start Redmine Server

```bash
cd /redmine-mcp/redmine-server
docker-compose up -d
```

### 3. Verify Redmine is Running

```bash
curl http://localhost:3000
```

## Obtaining a Redmine API Key

For the MCP client to connect to Redmine, you'll need an API key:

1. Access Redmine at http://localhost:3000
2. Log in with default credentials:
   - Username: admin
   - Password: admin
3. Go to "My account" (top-right menu)
4. On the right side, find "API access key"
5. Click "Show" or "Generate" to get your API key
6. Use this API key for MCP server configuration

## Redmine Configuration for MCP

The MCP client requires:
- Redmine URL: http://localhost:3000
- API Key: (from your Redmine account)
- MCP Version: 1.0

## Troubleshooting

If Redmine fails to start:

1. Check Docker logs:
   ```bash
   docker logs redmine-app
   docker logs redmine-postgres
   ```

2. Check port availability:
   ```bash
   lsof -i :3000
   lsof -i :5432
   ```

3. Restart Docker services:
   ```bash
   cd /redmine-mcp/redmine-server
   docker-compose down
   docker-compose up -d
   ```

## Important Notes

- Redmine data is stored in Docker volumes, so it persists between restarts
- Initial setup may take a few minutes to complete
- The default admin user should be changed after first login for security

## Best Practices

Following ModelContextProtocol (MCP) best practices:
1. Always work methodically on one task at a time
2. Validate each step before proceeding
3. Document your process thoroughly
4. Focus on security and stability
