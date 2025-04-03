# Instructions for Claude to Interact with Redmine Server

Claude, when interacting with the Redmine server at localhost:3000, follow these guidelines to ensure efficient API communication:

## Authentication

All requests to the Redmine API should include the API key:
```
d775369e8258a39cb774c23af78de43e10452b1c
```

## Command Structure

When formulating curl commands:
1. Always use single quotes around URLs
2. Always use 'Content-Type: application/json' for POST/PUT requests
3. Ensure proper JSON formatting in the request body
4. Use the following syntax for curl commands:

```bash
curl -X METHOD 'URL_WITH_PARAMS' -H 'Content-Type: application/json' -d 'JSON_PAYLOAD'
```

## Common Operations

### Reading Data
- Get all projects: `curl -s 'http://localhost:3000/projects.json?key=d775369e8258a39cb774c23af78de43e10452b1c'`
- Get issues for RedmineMCP: `curl -s 'http://localhost:3000/projects/1/issues.json?key=d775369e8258a39cb774c23af78de43e10452b1c'`

### Creating Issues
```bash
curl -X POST 'http://localhost:3000/issues.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"project_id":1,"subject":"Issue Title","description":"Detailed description","tracker_id":2}}'
```

### Updating Issues
```bash
curl -X PUT 'http://localhost:3000/issues/ISSUE_ID.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"subject":"Updated Title","description":"Updated description"}}'
```

## Project Structure Reference

### Project IDs
- RedmineMCP: ID 1
- agent-topics: ID 2

### Version IDs for RedmineMCP
- Phase 1 (Research and Planning): ID 1
- Phase 2 (Core Implementation): ID 2
- Phase 3 (Testing and Enhancement): ID 3
- Phase 4 (Deployment and Handover): ID 4

### Tracker IDs
- Bug: ID 1
- Feature: ID 2
- Support: ID 3

### Status IDs
- New: ID 1
- In Progress: ID 2
- Resolved: ID 3
- Closed: ID 5

## Avoiding Common Errors

1. Use single quotes around URLs to prevent shell interpretation of special characters
2. Format JSON with double quotes for keys and string values
3. Escape double quotes within JSON when necessary
4. Verify correct project IDs, version IDs, and other parameters before sending requests

Following these guidelines will help you efficiently interact with the Redmine server through API requests.
