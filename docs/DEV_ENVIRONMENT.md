# Redmine MCP Development Environment

## Overview

This document provides instructions for setting up a consistent development environment for the Redmine MCP system. The configuration uses predefined credentials to simplify development and testing.

## Development Environment Credentials

The development environment uses the following predefined credentials:

- **Redmine URL**: http://localhost:3000
- **Admin Username**: admin
- **Admin Password**: RedmineMCP!
- **API Token**: 7a4ed5c91b405d30fda60909dbc86c2651c38217

> **Note**: These credentials are for development purposes only and should never be used in a production environment.

## Quick Setup

To set up the development environment with predefined credentials:

```bash
bash /redmine-mcp/scripts/bootstrap-redmine-dev.sh
```

This script:
1. Cleans up any existing containers
2. Creates a customized Docker Compose file with predefined credentials
3. Starts the Redmine server
4. Ensures the API token is set correctly
5. Verifies Redmine is accessible

## How It Works

The bootstrap script modifies the standard Redmine Docker configuration to:

1. Set the admin password to "RedmineMCP!"
2. Set the API token to match the one in the MCP server configuration
3. Ensure these settings persist across container restarts

This provides a consistent environment where:
- The MCP server can always connect to Redmine without needing to update API keys
- Developers can log in with known credentials
- The environment can be quickly reset to a known state

## Testing the Connection

To verify the MCP server can connect to Redmine:

1. Access Redmine at http://localhost:3000
2. Log in with admin/RedmineMCP!
3. Confirm the API key shown matches "7a4ed5c91b405d30fda60909dbc86c2651c38217"

## ModelContextProtocol (MCP) Best Practices

When developing with this environment:

1. **Work Methodically**: Focus on one task at a time and validate before moving on
2. **Validate Each Step**: Verify functionality after each development phase
3. **Document Changes**: Keep documentation up-to-date with any configuration changes
4. **Process-Oriented**: Follow standard procedures for each operation

## Reverting to Original Configuration

If needed, you can revert to the original Redmine configuration:

```bash
cd /redmine-mcp/redmine-server
docker-compose down
cp docker-compose.yml.original docker-compose.yml
docker-compose up -d
```

## Next Steps

After setting up the development environment:

1. Develop and test MCP protocol interactions with Redmine
2. Create sample projects and issues for testing
3. Implement automated tests against this consistent environment
