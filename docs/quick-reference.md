# Redmine MCP Quick Reference Guide

This quick reference guide provides a concise summary of the most common Redmine MCP operations.

## Authentication

All MCP operations use the API key specified in the `redmine.yaml` configuration file.

## Project Operations

### List All Projects

```javascript
redmine_projects_list({
  limit: 25,     // Number of projects to return (default: 25)
  offset: 0,     // Pagination offset (default: 0)
  sort: "name:asc"  // Field to sort by with direction (default: name:asc)
})
```

### Get Project Details

```javascript
redmine_projects_get({
  identifier: "mcp-project",  // Project identifier
  include: ["trackers", "issue_categories"]  // Related data to include
})
```

## Issue Operations

### List Issues

```javascript
redmine_issues_list({
  project_id: "mcp-project",  // Filter by project identifier
  tracker_id: 1,              // Filter by tracker
  status_id: "open",          // Filter by status
  limit: 25,                  // Number of issues to return (default: 25)
  offset: 0,                  // Pagination offset (default: 0)
  sort: "updated_on:desc"     // Field to sort by (default: updated_on:desc)
})
```

### Get Issue Details

```javascript
redmine_issues_get({
  issue_id: 8,                // Issue ID
  include: ["journals", "watchers", "relations"]  // Related data to include
})
```

### Create an Issue

```javascript
redmine_issues_create({
  project_id: 1,              // Project ID
  subject: "Issue subject",   // Issue subject
  description: "Description", // Issue description
  tracker_id: 1,              // Tracker ID
  priority_id: 2,             // Priority ID
  status_id: 1,               // Status ID
  assigned_to_id: 3           // Assignee ID
})
```

### Update an Issue

```javascript
redmine_issues_update({
  issue_id: 8,                // Issue ID
  subject: "Updated subject", // New issue subject
  description: "New desc",    // New issue description
  status_id: 2,               // New status ID
  priority_id: 3,             // New priority ID
  assigned_to_id: 4           // New assignee ID
})
```

## User Operations

### Get Current User

```javascript
redmine_users_current({})
```

## Common Project IDs

| ID | Project Name    | Identifier  |
|----|----------------|-------------|
| 1  | MCP Project    | mcp-project |
| 4  | Hosted         | hosted      |
| 5  | bugs           | bugs        |
| 6  | docs           | docs        |
| 7  | features       | features    |

## Common Tracker IDs

| ID | Name             |
|----|-----------------|
| 1  | Bug             |
| 2  | Feature         |
| 3  | Support         |
| 4  | MCP Test Case   |
| 5  | MCP Documentation |

## Common Priority IDs

| ID | Name    |
|----|---------|
| 1  | Low     |
| 2  | Normal  |
| 3  | High    |
| 4  | Urgent  |

## Common Status IDs

| ID | Name        |
|----|-------------|
| 1  | New         |
| 2  | In Progress |
| 3  | Resolved    |
| 4  | Feedback    |
| 5  | Closed      |
| 6  | Rejected    |

## Common Workflows

### Add Time Tracking

```javascript
redmine_issues_update({
  issue_id: 8, 
  estimated_hours: 24
})
```

### Change Issue Status

```javascript
redmine_issues_update({
  issue_id: 8, 
  status_id: 2  // In Progress
})
```

### Reassign an Issue

```javascript
redmine_issues_update({
  issue_id: 8, 
  assigned_to_id: 3  // Developer
})
```

### Move an Issue to Different Project

```javascript
// This requires including all relevant fields!
redmine_issues_update({
  issue_id: 8, 
  project_id: 6,  // docs project
  // Include all these fields to maintain issue integrity
  subject: "Current subject",
  description: "Current description",
  tracker_id: 5,
  priority_id: 2,
  status_id: 1,
  assigned_to_id: 1
})
```

## Common Error Scenarios

1. **422 Unprocessable Entity**: Missing required fields or validation error
2. **404 Not Found**: Issue, project, or resource doesn't exist
3. **401 Unauthorized**: Invalid API key or insufficient permissions
4. **403 Forbidden**: User doesn't have permission for the operation

## Troubleshooting Tips

1. Always verify issue location after project transfers
2. Check that required fields are provided in all API calls
3. Ensure user has appropriate permissions for the operation
4. For complex operations, get the current state first, then update
