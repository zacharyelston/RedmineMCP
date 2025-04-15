# Redmine MCP Workflows Guide

## Introduction

This document explains the workflows configured in the Redmine MCP implementation. Workflows in Redmine define how issues move through different statuses based on user roles and issue types.

## Workflow Components

### Issue Statuses

The following statuses are defined in the system:

1. **New**: Issues that have just been created
2. **In Progress**: Issues that are actively being worked on
3. **Feedback**: Issues that require input from stakeholders
4. **Resolved**: Issues that have been completed but not verified
5. **Closed**: Issues that have been resolved and verified
6. **Rejected**: Issues that will not be implemented

### User Roles

The system has the following user roles:

1. **Admin**: Full system access
2. **Manager**: Project management capabilities
3. **Developer**: Responsible for implementing features and fixing bugs
4. **Reporter**: Can report issues and provide feedback

### Issue Types (Trackers)

Issue types define the nature of the work:

1. **Bug**: Something that's not working as expected
2. **Feature**: A new capability to be added
3. **Support**: A request for assistance
4. **Task**: A specific work item
5. **Epic**: A large feature that contains multiple stories
6. **Story**: A user story describing functionality from user perspective

## Workflow Configuration

The workflow rules define which roles can transition issues between which statuses, based on the issue type. Below are the primary workflows implemented:

### Bug Workflow

1. **New** → **In Progress**: Developer, Manager
2. **In Progress** → **Resolved**: Developer
3. **Resolved** → **Closed**: Manager, Reporter
4. **Resolved** → **Feedback**: Manager, Reporter
5. **Feedback** → **In Progress**: Developer
6. **In Progress** → **Feedback**: Developer
7. **New** → **Rejected**: Manager

### Feature Workflow

1. **New** → **In Progress**: Developer, Manager
2. **In Progress** → **Resolved**: Developer
3. **Resolved** → **Closed**: Manager
4. **Resolved** → **Feedback**: Manager, Reporter
5. **Feedback** → **In Progress**: Developer
6. **In Progress** → **Feedback**: Developer
7. **New** → **Rejected**: Manager

### Support Workflow

1. **New** → **In Progress**: Developer, Manager
2. **In Progress** → **Resolved**: Developer, Manager
3. **Resolved** → **Closed**: Manager, Reporter
4. **Resolved** → **Feedback**: Manager, Reporter
5. **Feedback** → **In Progress**: Developer, Manager
6. **New** → **Feedback**: Developer, Manager, Reporter

## MCP Integration with Workflows

The ModelContextProtocol (MCP) system integrates with Redmine workflows to enable automated actions and model-based interactions:

### 1. Workflow Triggers

MCP can trigger workflow transitions based on:
- Scheduled events
- External system events
- Model evaluations 
- Time-based rules

### 2. Automated Actions

When workflow transitions occur, MCP can:
- Send notifications
- Create related issues
- Update fields
- Generate reports
- Trigger external systems

### 3. Model-Based Decision Support

MCP can assist with workflow decisions by:
- Analyzing issue content
- Suggesting appropriate assignees
- Predicting resolution time
- Identifying related issues
- Recommending next steps

## Example MCP Workflow Commands

The following MCP commands can be used to interact with workflows:

### List Available Transitions

```
[MCP]
Command: rmcp.workflow.getTransitions
Parameters:
  issueId: 123
[/MCP]
```

### Transition an Issue

```
[MCP]
Command: rmcp.workflow.transition
Parameters:
  issueId: 123
  status: "In Progress"
  comment: "Starting work on this issue"
[/MCP]
```

### Create a Related Issue

```
[MCP]
Command: rmcp.issue.create
Parameters:
  projectId: "mcp-project"
  subject: "Related testing task"
  description: "Testing for issue #123"
  parentId: 123
  trackerId: 4  # Task
[/MCP]
```

## Testing Workflows

To test the workflows, you can use the test-redmine-api.sh script:

```bash
# Get available transitions for an issue
./scripts/test-redmine-api.sh -k 7a4ed5c91b405d30fda60909dbc86c26 -e '/issues/1.json?include=journals,watchers,relations'

# Update an issue status
./scripts/test-redmine-api.sh -k f91c59b0d78f2a10d9b7ea3c631d9f2c -e '/issues/1.json' -m PUT -d '{"issue":{"status_id":2}}'
```

## Workflow Testing Scenarios

1. **Bug Resolution Flow**:
   - Create a new bug as Reporter
   - Transition to In Progress as Developer
   - Resolve the bug as Developer
   - Verify and Close as Manager

2. **Feature Development Flow**:
   - Create a new feature as Manager
   - Assign to Developer
   - Transition to In Progress as Developer
   - Request Feedback as Developer
   - Provide Feedback as Manager
   - Return to In Progress as Developer
   - Resolve as Developer
   - Close as Manager

3. **Support Request Flow**:
   - Create a support request as Reporter
   - Request more information (Feedback) as Developer
   - Provide information as Reporter
   - Transition to In Progress as Developer
   - Resolve as Developer
   - Close as Reporter
