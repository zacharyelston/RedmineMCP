# Troubleshooting Guide for RedmineMCP

*Note: Ideally, this file should be in a `docs/` directory.*

This guide addresses common issues and solutions encountered when working with RedmineMCP and the Redmine API.

## Redmine API Issues

### "Priority cannot be blank" Error

**Problem**: When creating issues, you get the error "Priority cannot be blank" even though you specified a priority_id.

**Solution**:
1. Verify that priorities exist in your Redmine instance:
   ```bash
   curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/enumerations/issue_priorities.json"
   ```
2. If the response shows an empty list, you need to create priorities through the Redmine web interface:
   - Go to Administration > Enumerations > Issue priorities
   - Add priorities like "low", "medium", and "high"
   - Set one as the default

3. After creating priorities, use the correct priority_id in your requests.

### Missing Trackers

**Problem**: Creating issues fails due to invalid tracker_id.

**Solution**:
1. Check available trackers:
   ```bash
   curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/trackers.json"
   ```
2. If trackers are missing, they need to be created in the Redmine web interface:
   - Go to Administration > Trackers
   - Add standard trackers like "Bug", "Feature", and "Support"

### Time Tracking "Activity is not included in the list" Error

**Problem**: When logging time, you get "Activity is not included in the list" error.

**Solution**:
1. Check available time entry activities:
   ```bash
   curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/enumerations/time_entry_activities.json"
   ```
2. Create necessary activities through the Redmine web interface:
   - Go to Administration > Enumerations > Activities (time tracking)
   - Add activities like "dev", "review", and "waiting"
3. Use the correct activity_id in your time entry requests.

### API Key Authentication Issues

**Problem**: API requests failing with 401 Unauthorized.

**Solution**:
1. Verify your API key is correct in credentials.yaml
2. Ensure the API key belongs to an admin user for administrative operations
3. Check that Redmine's REST API is enabled in Administration > Settings > API

### Complex JSON with curl

**Problem**: curl commands with complex JSON data fail with parsing errors.

**Solution**:
1. Use single quotes around the entire JSON data:
   ```bash
   curl -X POST "http://localhost:3000/issues.json" \
     -H "Content-Type:application/json" \
     -H "X-Redmine-API-Key:YOUR_API_KEY" \
     -d '{"issue":{"project_id":1,"subject":"Test issue"}}'
   ```
2. For very complex JSON, store it in a file and use:
   ```bash
   curl -X POST "http://localhost:3000/issues.json" \
     -H "Content-Type:application/json" \
     -H "X-Redmine-API-Key:YOUR_API_KEY" \
     --data @filename.json
   ```
3. Avoid escaping issues by using a dedicated HTTP client library in Python or JavaScript

## MCP Extension Issues

### Connection to Redmine Failed

**Problem**: MCP extension cannot connect to Redmine.

**Solution**:
1. Check the `redmine_url` in credentials.yaml
2. If using Docker, ensure proper network configuration:
   - In Docker environments, use the container name (e.g., "http://redmine:3000") 
   - For local development, use "http://localhost:3000"
3. Use the health check endpoint to diagnose:
   ```bash
   curl http://localhost:9000/api/health
   ```

### LLM API Connection Issues

**Problem**: MCP extension cannot connect to the LLM API (Claude or OpenAI).

**Solution**:
1. Verify your API key in credentials.yaml
2. Check for rate limiting issues
3. Ensure internet connectivity from the MCP extension container
4. Verify the selected LLM provider is correctly configured

### Docker Configuration Issues

**Problem**: Docker containers not communicating properly.

**Solution**:
1. Ensure containers are on the same Docker network
2. Check port mappings and container names
3. Use Docker's network debugging:
   ```bash
   docker network inspect bridge
   ```
4. For ARM64 architecture (M1/M2 Macs):
   - Use MariaDB instead of MySQL
   - Apply special workarounds for Container KeyError issues

## Development Environment Issues

### Python Dependencies

**Problem**: Missing Python dependencies when running scripts.

**Solution**:
1. Install required packages:
   ```bash
   pip install redminelib pyyaml requests
   ```
2. Use the provided scripts/bootstrap_redmine.sh which checks for dependencies

### API Testing Issues

**Problem**: Difficulty testing complex API operations.

**Solution**:
1. Use the provided test scripts in the scripts directory:
   - scripts/test_redmine_api_functionality.py
   - scripts/validate_redmine_api.sh
2. For complex operations like file uploads, use a Python script with requests library
3. Consider using a tool like Postman for interactive API testing
