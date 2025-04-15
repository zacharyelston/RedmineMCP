# Redmine MCP Integration: Basic Usage Guide

## Introduction

The Model Context Protocol (MCP) integration with Redmine provides a streamlined way to interact with Redmine projects and issues through a consistent API. This document covers the basic usage of the Redmine MCP integration, helping you get started with common operations.

## Setting Up

### Prerequisites

- Redmine server running (default: http://localhost:3000)
- API key for authentication
- MCP client tools installed

### Configuration

The Redmine MCP integration is configured through the `redmine.yaml` file, which contains server information, project structure, and implementation details. While this file is used for reference, all interactions with Redmine should be performed using the MCP tools.

## Basic Commands

The Redmine MCP integration provides several commands for interacting with Redmine:

### Listing Projects

To list all accessible Redmine projects:

```javascript
redmine_projects_list({limit: 100})
```

### Getting Project Details

To get details of a specific Redmine project:

```javascript
redmine_projects_get({identifier: 'mcp-project', include: ['trackers', 'issue_categories']})
```

### Listing Issues

To list issues with optional filtering:

```javascript
redmine_issues_list({project_id: 1, limit: 100})
```

### Getting Issue Details

To get details of a specific issue:

```javascript
redmine_issues_get({issue_id: 8})
```

### Creating Issues

To create a new issue:

```javascript
redmine_issues_create({
  project_id: 1, 
  subject: 'New task', 
  description: 'Task description', 
  tracker_id: 2, 
  priority_id: 2, 
  assigned_to_id: 1
})
```

### Updating Issues

To update an existing issue:

```javascript
redmine_issues_update({
  issue_id: 8, 
  subject: 'Updated title', 
  status_id: 2
})
```

### Getting Current User Information

To get information about the current user:

```javascript
redmine_users_current({})
```

## Common Workflows

### Adding Time Tracking to an Issue

```javascript
redmine_issues_update({issue_id: 8, estimated_hours: 24})
```

### Changing Issue Status

```javascript
redmine_issues_update({issue_id: 8, status_id: 2})
```

### Reassigning an Issue

```javascript
redmine_issues_update({issue_id: 8, assigned_to_id: 3})
```

### Moving an Issue to a Different Project

```javascript
redmine_issues_update({issue_id: 8, project_id: 4})
```

**Note:** Moving issues between projects requires special handling. The Redmine API requires all relevant fields to be included in project transfer requests to maintain issue integrity.

## Project Structure

The MCP Project in Redmine has the following structure:

### Subprojects

1. **Hosted (ID: 4)**: The hosted dev/test/prod environment configuration
2. **bugs (ID: 5)**: Bug tracking and issue management
3. **docs (ID: 6)**: Documentation for MCP project
4. **features (ID: 7)**: New feature development

### Categories

- Backend
- Frontend
- Documentation
- Infrastructure

### Trackers

1. Bug
2. Feature
3. Support
4. MCP Test Case
5. MCP Documentation

### Priorities

1. Low
2. Normal
3. High
4. Urgent

## Troubleshooting

### Common Pitfalls

- Simple parameter updates work for most fields but not for project transfers
- API returns success even when project transfers silently fail
- Missing fields in update payload can cause project transfers to fail
- Always verify issue location after project transfers

### Implementation Insights

- When transferring issues between projects, the complete issue data must be preserved
- The Redmine API requires all relevant fields to be included in project transfer requests
- The enhanced RedmineClient.ts implementation fetches current issue data before updating
- Special handling is needed for project_id updates to maintain issue integrity
- Including notes with project transfers helps with tracking changes

## Best Practices

- Always use the MCP tools provided in this file for interacting with the Redmine project
- Direct API calls should be avoided in favor of the MCP protocol
- Verify the success of operations, especially project transfers
- Use detailed error logging for better troubleshooting

## Next Steps

After mastering the basic usage, you can explore more advanced features:

1. Creating proper parent-child relationships between issues
2. Adding estimated hours for better time tracking
3. Creating more detailed work breakdown structures
4. Adding milestone tracking with due dates
5. Implementing version management for releases

For more detailed information on specific operations, refer to the comprehensive API documentation.
