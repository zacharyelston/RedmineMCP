# Redmine MCP Server Networking Solution

## Problem Identification

After careful analysis, we've identified the core issue with the Redmine MCP connection:

1. The Redmine server is running from `/Users/zacelston/CODE/MCPZ/redmine1/` with its own Docker bridge network.
2. The MCP server in `/redmine-mcp/` is using the host network mode and trying to connect to `localhost` or `redmine.local`.
3. These different networking approaches are preventing proper communication between the services.

## Solution Overview

Our solution implements a shared Docker network that allows direct container-to-container communication using Docker's built-in DNS resolution. This approach has several advantages:

1. **Service Discovery**: Containers can reference each other by service name
2. **Network Isolation**: Improved security by isolating services in their own network
3. **No Host File Modifications**: No need to modify `/etc/hosts` or use special DNS configurations
4. **Docker Best Practices**: Follows recommended Docker networking patterns

## Implementation Details

### 1. Network Configuration Changes

We've created updated Docker Compose files that:

- Define a shared external Docker network named `redmine-mcp-network`
- Connect both the Redmine and MCP services to this network
- Configure the MCP server to connect to Redmine using its service name (`http://redmine-app:3000`)

### 2. Key Configuration Changes

#### Redmine Server (`docker-compose.yml`)
- Changed from using a private `redmine-network` to a shared `redmine-mcp-network`
- Made the network name consistent and externally reusable

```yaml
networks:
  redmine-mcp-network:
    name: redmine-mcp-network
    driver: bridge
    external: false # Set to true after initial creation
```

#### MCP Server (`docker-compose.yml`)
- Removed the `network_mode: host` directive
- Connected to the shared `redmine-mcp-network` instead
- Updated connection to use Docker's DNS resolution

```yaml
environment:
  REDMINE_URL: http://redmine-app:3000
  
networks:
  redmine-mcp-network:
    name: redmine-mcp-network
    driver: bridge
    external: true
```

#### MCP Server Configuration (`config.json`)
- Updated to use the Docker service name for Redmine

```json
{
  "redmine_url": "http://redmine-app:3000",
  "redmine_api_key": "7a4ed5c91b405d30fda60909dbc86c2651c38217",
  "log_level": "info",
  "mcp_version": "1.0"
}
```

### 3. Deployment Process

We've created a deployment script (`deploy-shared-network.sh`) that:

1. Backs up all original configuration files
2. Applies the new configuration files
3. Creates the shared Docker network
4. Deploys the Redmine server first (creating the network)
5. Deploys the MCP server (connecting to the existing network)
6. Provides verification steps and rollback instructions

## Testing and Verification

After deployment, you can verify the connection with:

```bash
docker exec -it redmine-mcp-server curl http://redmine-app:3000
```

This should return the Redmine HTML page, confirming that the MCP server can connect to Redmine.

## Advantages of This Approach

1. **Direct Container Communication**: Uses Docker's built-in DNS to resolve service names
2. **No Host System Changes**: No need to modify host files or DNS settings
3. **Consistent Development Environment**: Same configuration works across all development machines
4. **Better Security**: Services are isolated within their own network
5. **Standard Docker Practice**: Uses recommended Docker networking patterns

## Rollback Procedure

If needed, you can revert to the original configuration by restoring the backup files:

```bash
# Restore Redmine config
cd /Users/zacelston/CODE/MCPZ/redmine1
cp docker-compose.yml.backup.* docker-compose.yml

# Restore MCP configs
cd /redmine-mcp/mcp-server
cp docker-compose.yml.backup.* docker-compose.yml
cp config/config.json.backup.* config/config.json

# Restart services
cd /Users/zacelston/CODE/MCPZ/redmine1
docker-compose down
docker-compose up -d

cd /redmine-mcp/mcp-server
docker-compose down
docker-compose up -d
```

## MCP Best Practices Followed

This solution adheres to the ModelContextProtocol (MCP) best practices by:

1. **Working Methodically**: Focused on a clear networking approach
2. **Validating Each Step**: Script includes verification points
3. **Showing Work**: Detailed documentation of changes
4. **Careful Execution**: Includes backups and rollback procedures
5. **Process-Oriented**: Follows a repeatable process for reliability

## Conclusion

This Docker networking solution provides a robust, secure, and maintainable approach to connecting the Redmine and MCP servers. The solution follows Docker best practices and MCP development principles to ensure reliable operation.
