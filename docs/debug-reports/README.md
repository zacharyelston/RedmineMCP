# Redmine MCP Server Debug Documentation

## Connection Issue Fix Instructions

### Overview
This document provides instructions for resolving the connection issue between the Redmine MCP server and the Redmine application server. The problem is that the MCP server is unable to connect to Redmine at `http://localhost:3000`.

### Prerequisites
- Access to both the Redmine and MCP server configurations
- Administrator privileges (for modifying `/etc/hosts`)
- Docker and Docker Compose installed and running

### Step-by-Step Fix Instructions

#### 1. Add Host Entry
Add an entry in `/etc/hosts` to map `redmine.local` to `127.0.0.1`:

```bash
# Run this command with administrator privileges
sudo sh -c "echo '127.0.0.1 redmine.local' >> /etc/hosts"
```

#### 2. Update MCP Server Configuration
Edit the `mcp-server/config/config.json` file to use the new hostname:

```json
{
  "redmine_url": "http://redmine.local:3000",
  "redmine_api_key": "7a4ed5c91b405d30fda60909dbc86c2651c38217",
  "log_level": "info",
  "mcp_version": "1.0"
}
```

#### 3. Update Docker Compose Configuration
Edit the `mcp-server/docker-compose.yml` file to update the environment variables:

```yaml
environment:
  REDMINE_URL: http://redmine.local:3000
  REDMINE_API_KEY: ${REDMINE_API_KEY:-7a4ed5c91b405d30fda60909dbc86c2651c38217}
  LOG_LEVEL: ${LOG_LEVEL:-info}
  SKIP_CONNECTION_TEST: ${SKIP_CONNECTION_TEST:-false}
```

#### 4. Restart Services
Restart both services to apply the changes:

```bash
# Restart Redmine server
cd /redmine-mcp/redmine-server
docker-compose down
docker-compose up -d

# Restart MCP server
cd /redmine-mcp/mcp-server
docker-compose down
docker-compose up -d
```

#### 5. Verify Connection
Verify that the connection is working:

```bash
curl http://redmine.local:3000
```

### Using the Fix Script
We have provided a script to automate these changes:

1. Make the script executable:
   ```bash
   chmod +x /redmine-mcp/scripts/fix-redmine-connection.sh
   ```

2. Run the script:
   ```bash
   /redmine-mcp/scripts/fix-redmine-connection.sh
   ```

3. Follow the on-screen instructions to complete the fix.

### Alternative Approaches

If the host alias approach doesn't work, consider these alternatives:

1. **Docker Network Bridge**:
   - Create a shared network for both containers
   - Use service discovery to connect between containers

2. **Expose Redmine on All Interfaces**:
   - Update the Redmine server to bind to all interfaces (0.0.0.0)
   - Ensure proper security measures are in place

3. **Use Docker Compose Networking**:
   - Put both services in the same Docker Compose file
   - Use service names for DNS resolution

## Troubleshooting

If issues persist after applying these fixes:

1. Check Docker logs:
   ```bash
   docker-compose logs -f redmine-app       # For Redmine logs
   docker-compose logs -f redmine-mcp-server # For MCP server logs
   ```

2. Verify that Redmine is running and accessible:
   ```bash
   curl http://redmine.local:3000
   ```

3. Check network connectivity between containers:
   ```bash
   docker exec -it redmine-mcp-server ping redmine.local
   ```

## Additional Notes

- The original configuration files are backed up with the `.bak` extension
- If you need to revert changes, simply restore the backup files
- Always follow MCP best practices: work methodically and validate each step

For more detailed analysis, refer to the [connection debug report](redmine-mcp-connection-debug.md) in this directory.
