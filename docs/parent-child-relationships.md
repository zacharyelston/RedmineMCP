# Redmine Parent-Child Relationships

This document describes how to work with parent-child relationships (subtasks) in the Redmine MCP toolkit.

## Overview

Redmine allows creating hierarchical relationships between issues, where one issue can be designated as the parent of other issues. This creates a hierarchical structure with parent issues and subtasks, making it easier to organize and track complex work.

The Redmine MCP toolkit provides several methods to work with these parent-child relationships:

1. Creating subtasks directly with the `parent_issue_id` parameter
2. Using the helper `createSubtask` method
3. Setting/updating parent relationships for existing issues
4. Retrieving child issues of a parent

## Creating Subtasks

### Method 1: Using createIssue with parent_issue_id

```typescript
// Create a subtask by specifying the parent_issue_id parameter
const subtask = await client.createIssue(
  projectId,        // The project ID (must be same as parent's project)
  "Subtask Title",  // Subject 
  "Description",    // Description (optional)
  trackerId,        // Tracker ID (optional)
  statusId,         // Status ID (optional)
  priorityId,       // Priority ID (optional)
  assignedToId,     // Assignee ID (optional)
  parentIssueId     // Parent issue ID
);
```

### Method 2: Using the createSubtask helper

```typescript
// Create a subtask using the helper method
// The project ID is automatically determined from the parent issue
const subtask = await client.createSubtask(
  parentIssueId,    // Parent issue ID
  "Subtask Title",  // Subject
  "Description",    // Description (optional)
  trackerId,        // Tracker ID (optional)
  statusId,         // Status ID (optional)
  priorityId        // Priority ID (optional)
);
```

## Setting/Updating Parent Relationships

### Method 1: Using setParentIssue

```typescript
// Set or change the parent of an existing issue
const success = await client.setParentIssue(
  issueId,          // Issue ID to update
  parentIssueId     // Parent issue ID
);
```

### Method 2: Using updateIssue

```typescript
// Set or change the parent using the general update method
const success = await client.updateIssue(
  issueId,          // Issue ID to update
  { parent_issue_id: parentIssueId }  // Update parameters
);
```

### Removing a Parent Relationship

```typescript
// Remove the parent relationship (make it a top-level issue)
const success = await client.removeParentIssue(issueId);

// Alternative using updateIssue
const success = await client.updateIssue(issueId, { parent_issue_id: '' });
```

## Retrieving Child Issues

```typescript
// Get all child issues of a parent issue
const childIssues = await client.getChildIssues(parentIssueId);

// Alternative using getIssue with 'children' included
const parentIssue = await client.getIssue(parentIssueId, ['children']);
const childIssues = parentIssue.children || [];
```

## MCP Tools

The following MCP tools are available for working with parent-child relationships:

### redmine_issues_create

```javascript
// Create an issue with a parent (creates a subtask)
redmine_issues_create({
  project_id: 1,
  subject: "Subtask Title",
  description: "Description",
  tracker_id: 2,
  priority_id: 2,
  parent_issue_id: 123  // Specify parent issue ID
})
```

### redmine_issue_set_parent

```javascript
// Set the parent of an existing issue
redmine_issue_set_parent({
  issue_id: 456,
  parent_issue_id: 123
})
```

### redmine_issue_remove_parent

```javascript
// Remove the parent relationship
redmine_issue_remove_parent({
  issue_id: 456
})
```

### redmine_issue_get_children

```javascript
// Get all child issues of a parent
redmine_issue_get_children({
  parent_issue_id: 123
})
```

### redmine_issue_create_subtask

```javascript
// Create a subtask (helper tool)
redmine_issue_create_subtask({
  parent_issue_id: 123,
  subject: "Subtask Title",
  description: "Description",
  tracker_id: 2,
  priority_id: 2
})
```

## Best Practices

1. **Project Consistency**: When creating subtasks directly with `createIssue`, make sure to use the same project ID as the parent issue. Using a different project ID can cause unexpected behavior.

2. **Verification**: Always verify that the parent-child relationship was established correctly after creation, especially for mission-critical tasks.

3. **Error Handling**: Handle errors gracefully, especially when the parent issue doesn't exist or is not accessible.

4. **Use Helper Methods**: Whenever possible, use the helper methods (`createSubtask`, `setParentIssue`, `getChildIssues`) rather than the general methods, as they provide additional validation and error handling.

## Example Usage

```javascript
// Create a parent issue
const parentIssue = await redmineClient.createIssue(
  1,                                // Project ID
  "Parent Task: Website Redesign",  // Subject
  "Main task for website redesign", // Description
  2,                                // Feature tracker
  1,                                // New status
  2                                 // Normal priority
);

// Create subtasks
const subtask1 = await redmineClient.createSubtask(
  parentIssue.id,                  // Parent issue ID
  "Subtask: Design Homepage",      // Subject
  "Create new homepage design",    // Description
  2,                               // Feature tracker
  1,                               // New status
  2                                // Normal priority
);

const subtask2 = await redmineClient.createSubtask(
  parentIssue.id,                  // Parent issue ID
  "Subtask: Update CSS",           // Subject
  "Update CSS for new design",     // Description
  2,                               // Feature tracker
  1,                               // New status
  2                                // Normal priority
);

// Get all subtasks
const childIssues = await redmineClient.getChildIssues(parentIssue.id);
console.log(`Found ${childIssues.length} subtasks`);
```
