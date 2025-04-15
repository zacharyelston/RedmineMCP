# Redmine MCP API Testing Reference

## Overview

This quick reference guide provides common curl commands for testing the Redmine API in the ModelContextProtocol (MCP) implementation.

## API Keys

```
Admin:     admin_api_key
Test User: test_api_key
Developer: dev_api_key
Manager:   manager_api_key
```

## Basic API Commands

### Get Current User

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/users/current.json
```

### List All Projects

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/projects.json
```

### Get MCP Project Details

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/projects/mcp-project.json?include=trackers,issue_categories,enabled_modules
```

### List All Issues

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/issues.json?limit=100
```

### Get Project Issues

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/issues.json?project_id=mcp-project
```

### Get Issue Details

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     http://localhost:3000/issues/1.json?include=journals,watchers,relations
```

## Creating New Data

### Create a New Issue

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"issue":{"project_id":"mcp-project","subject":"Test issue","description":"This is a test issue created via API","tracker_id":1,"priority_id":2}}' \
     http://localhost:3000/issues.json
```

### Create a Time Entry

```bash
curl -H "X-Redmine-API-Key: dev_api_key" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"time_entry":{"issue_id":1,"hours":2,"activity_id":9,"comments":"Working on implementing the feature"}}' \
     http://localhost:3000/time_entries.json
```

## Updating Data

### Update an Issue

```bash
curl -H "X-Redmine-API-Key: admin_api_key" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{"issue":{"notes":"Updating the issue status","status_id":2,"assigned_to_id":3}}' \
     http://localhost:3000/issues/1.json
```

### Add a Comment to an Issue

```bash
curl -H "X-Redmine-API-Key: test_api_key" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{"issue":{"notes":"Adding a comment as the test user"}}' \
     http://localhost:3000/issues/1.json
```

## Testing Workflows

### Transition Issue to In Progress (Developer)

```bash
curl -H "X-Redmine-API-Key: dev_api_key" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{"issue":{"status_id":2,"notes":"Starting work on this issue"}}' \
     http://localhost:3000/issues/1.json
```

### Resolve an Issue (Developer)

```bash
curl -H "X-Redmine-API-Key: dev_api_key" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{"issue":{"status_id":3,"notes":"Issue has been fixed, ready for testing"}}' \
     http://localhost:3000/issues/1.json
```

### Close an Issue (Manager)

```bash
curl -H "X-Redmine-API-Key: manager_api_key" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{"issue":{"status_id":5,"notes":"Verified the fix, closing the issue"}}' \
     http://localhost:3000/issues/1.json
```

## Using the Test Script

For easier testing, use the provided test script:

```bash
# Get project details
./scripts/test-redmine-api.sh -k admin_api_key -e '/projects/mcp-project.json' -o '/tmp/project.json'

# Create a new issue
./scripts/test-redmine-api.sh -k admin_api_key -e '/issues.json' -m POST -d '{"issue":{"project_id":"mcp-project","subject":"API Test","description":"Testing the API","tracker_id":1}}' -o '/tmp/new_issue.json'

# Update an issue
./scripts/test-redmine-api.sh -k dev_api_key -e '/issues/1.json' -m PUT -d '{"issue":{"status_id":2,"notes":"Starting work"}}' 
```

## Troubleshooting API Access

If you're having trouble accessing the API, try these steps:

### 1. Verify REST API is Enabled

Check via the web interface:
- Log in as admin at http://localhost:3000
- Go to Administration > Settings > API
- Ensure "Enable REST web service" is checked

Or check via database:
```bash
docker exec redmine-postgres psql -U redmine -d redmine -c "SELECT * FROM settings WHERE name = 'rest_api_enabled'"
```

### 2. Generate a New API Key

If the existing API keys don't work, generate a new one:
- Log in to Redmine web interface
- Go to My account > API access key
- Click "Show" to view your current key
- Click "Reset" to generate a new key
- Try using the new key for API requests

### 3. Check API User Permissions

Make sure the user has appropriate permissions:
- Check that the user exists: `docker exec redmine-postgres psql -U redmine -d redmine -c "SELECT * FROM users WHERE login = 'admin'"`
- Check that the user has an API token: `docker exec redmine-postgres psql -U redmine -d redmine -c "SELECT * FROM tokens WHERE user_id = 1 AND action = 'api'"`

### 4. Try Basic Authentication

If API keys aren't working, try basic authentication:
```bash
curl -u admin:password -H "Content-Type: application/json" http://localhost:3000/users/current.json
```

### 5. Check Container Logs

Examine container logs for authentication issues:
```bash
docker logs redmine-app | grep -i auth
```

### 6. Restart Redmine

Sometimes restarting Redmine can help:
```bash
docker restart redmine-app
```

## Common HTTP Status Codes

- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **204 No Content**: Successful delete operation
- **401 Unauthorized**: Invalid or missing API key
- **403 Forbidden**: Not authorized to perform action
- **404 Not Found**: Resource not found
- **422 Unprocessable Entity**: Validation errors

## Additional Resources

For more detailed information, refer to the Redmine API documentation:
- Redmine REST API: http://www.redmine.org/projects/redmine/wiki/Rest_api
