# Redmine MCP Server Connection Debug Report

## Problem Analysis

### Observed Issue
- The MCP server is failing to connect to Redmine with the error: `Failed to connect to Redmine at http://localhost:3000`

### Root Cause Analysis
1. **Connection Configuration Mismatch**:
   - In `mcp-server/config/config.json`, the Redmine URL is set to: `http://host.docker.internal:3000`
   - However, in the log file, the server is trying to connect to: `http://localhost:3000`
   
2. **Docker Host Resolution**:
   - The MCP server's Docker configuration uses `network_mode: host` and includes `host.docker.internal:host-gateway`
   - Despite this, the attempt to connect to the host machine is failing

3. **Configuration Issues**:
   - The `entrypoint.sh` script overrides the configuration in `config.json` with the environment variable `REDMINE_URL`
   - The environment variable likely defaults to `http://localhost:3000` instead of using the config file value

## Proposed Solutions

### 1. Host Name Resolution Fix (Recommended)
- Add an entry in `/etc/hosts` to map `redmine.local` to `127.0.0.1`
- Update both Docker Compose files and the configuration files to use `redmine.local` instead of `localhost` or `host.docker.internal`

### 2. Configuration Consistency
- Ensure environment variables in Docker Compose match the configuration file:
```yaml
environment:
  REDMINE_URL: http://host.docker.internal:3000  # Or use redmine.local
```

### 3. Docker Network Bridge
- Instead of using `network_mode: host`, create a common network bridge that both services can use

## Implementation Plan

### Step 1: Update /etc/hosts
```bash
sudo sh -c "echo '127.0.0.1 redmine.local' >> /etc/hosts"
```

### Step 2: Update MCP Server Configuration
1. Edit `mcp-server/config/config.json`:
```json
{
  "redmine_url": "http://redmine.local:3000",
  "redmine_api_key": "7a4ed5c91b405d30fda60909dbc86c2651c38217",
  "log_level": "info",
  "mcp_version": "1.0"
}
```

2. Edit `mcp-server/docker-compose.yml`:
```yaml
environment:
  REDMINE_URL: http://redmine.local:3000
  REDMINE_API_KEY: ${REDMINE_API_KEY:-7a4ed5c91b405d30fda60909dbc86c2651c38217}
  LOG_LEVEL: ${LOG_LEVEL:-info}
  SKIP_CONNECTION_TEST: ${SKIP_CONNECTION_TEST:-false}
```

### Step 3: Update Redmine Server Configuration
1. Edit `redmine-server/docker-compose.yml` to expose the service on the host network:
```yaml
ports:
  - "127.0.0.1:3000:3000"  # Bind to localhost only
```

### Step 4: Test Connection
1. Restart both services:
```bash
cd /redmine-mcp/redmine-server
docker-compose down
docker-compose up -d

cd /redmine-mcp/mcp-server
docker-compose down
docker-compose up -d
```

2. Verify connection:
```bash
curl http://redmine.local:3000
```

## Additional Recommendations

1. **Improve Error Handling**:
   - Update the `entrypoint.sh` script to provide more detailed error messages
   - Add retry logic for connection failures

2. **Logging Enhancements**:
   - Implement structured logging to make debugging easier
   - Log the exact URL being used for connection attempts

3. **Development Environment Check**:
   - Create a simple health check script to verify connectivity before starting the MCP server

This approach follows the MCP best practices of working methodically and carefully to validate each step before moving forward.
