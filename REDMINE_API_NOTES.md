# Redmine API Developer Notes

This document contains practical knowledge and examples for working with the Redmine API in the RedmineMCP project.

## Setup and Configuration

### API Key Access
- The Redmine API key is stored in `credentials.yaml` 
- Always use the API key with the `X-Redmine-API-Key` header

### Required Resources for Redmine
Before creating issues, ensure Redmine has the following configured:
- Issue priorities (low, medium, high)
- Issue statuses (at minimum, "New")
- Time entry activities (e.g., "dev", "review", "waiting")

## Working with Projects

### Creating a Project
```bash
curl -X POST "http://localhost:3000/projects.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"project":{"name":"Project Name","identifier":"project-identifier","description":"Project description","is_public":true}}'
```

### Retrieving Projects
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/projects.json"
```

## Working with Issues

### Creating an Issue
```bash
curl -X POST "http://localhost:3000/issues.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"issue":{"project_id":1,"subject":"Issue subject","description":"Issue description","tracker_id":2,"priority_id":1}}'
```

Important parameters:
- `project_id`: ID of the project
- `tracker_id`: 1 for Bug, 2 for Feature, 3 for Support (can vary per installation)
- `priority_id`: ID of the priority (e.g., 1 for low, 6 for high, 7 for medium)

### Retrieving an Issue
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/issues/ISSUE_ID.json"
```

### Updating an Issue

Add a note to an issue:
```bash
curl -X PUT "http://localhost:3000/issues/ISSUE_ID.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"issue":{"notes":"This is a note added via the API."}}'
```

Update estimated hours:
```bash
curl -X PUT "http://localhost:3000/issues/ISSUE_ID.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"issue":{"estimated_hours":16}}'
```

### Adding a Watcher
```bash
curl -X POST "http://localhost:3000/issues/ISSUE_ID/watchers.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"user_id":USER_ID}'
```

## Time Tracking

### Logging Time on an Issue
```bash
curl -X POST "http://localhost:3000/time_entries.json" \
  -H "Content-Type:application/json" \
  -H "X-Redmine-API-Key:YOUR_API_KEY" \
  -d '{"time_entry":{"issue_id":ISSUE_ID,"hours":2.5,"activity_id":ACTIVITY_ID,"comments":"Work description"}}'
```

Note: You must use a valid `activity_id` from the time entry activities enumeration.

### Getting Time Entry Activities
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/enumerations/time_entry_activities.json"
```

## Enumerations

Redmine uses enumerations for various dropdown selections. These must be created in the Redmine admin UI before they can be used via API.

### Issue Priorities
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/enumerations/issue_priorities.json"
```

### Issue Statuses
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/issue_statuses.json"
```

### Trackers
```bash
curl -H "X-Redmine-API-Key:YOUR_API_KEY" "http://localhost:3000/trackers.json"
```

## File Attachments

Uploading attachments requires multipart/form-data requests, which are more complex than simple JSON requests. For file uploads, consider using a dedicated Redmine client library or a more advanced HTTP client that supports multipart/form-data.

## Known Limitations

1. **Creating Enumerations**: There's no REST API endpoint for creating priorities, statuses, or other enumerations. These must be created through the Redmine web interface.

2. **File Attachments**: Basic curl commands are insufficient for file uploads; use a library that supports multipart/form-data.

3. **Error Handling**: The API may return unclear error messages. Test with small, incremental changes when encountering issues.

## Best Practices

1. **Validate IDs**: Always validate project_id, tracker_id, and priority_id before creating issues.

2. **Escape JSON**: When using curl, properly escape JSON data to avoid command-line interpretation issues.

3. **API Access Configuration**: Ensure the REST API is enabled in Redmine administration settings.

4. **Rate Limiting**: Implement rate limiting in your applications to avoid overwhelming the Redmine server.

5. **Error Checking**: Always check HTTP status codes and error responses from the API.
