# Redmine MCP Workflow Guide

## Overview

This guide provides detailed information on using the Redmine workflows configured for the ModelContextProtocol (MCP) implementation. Workflows define how issues progress through different states and which roles can perform these transitions.

## Available Workflows

The MCP implementation includes the following workflow configurations:

### Issue Statuses

| Status      | Description                                           | Closed |
|-------------|-------------------------------------------------------|--------|
| New         | Issue has been created but work hasn't started        | No     |
| In Progress | Active work is being done on the issue                | No     |
| Feedback    | Issue needs additional information                    | No     |
| Resolved    | Work is complete but needs verification               | No     |
| Closed      | Issue has been verified and is complete               | Yes    |
| Rejected    | Issue will not be implemented                         | Yes    |

### Roles and Permissions

| Role       | Description                                        | Key Responsibilities                           |
|------------|----------------------------------------------------|------------------------------------------------|
| Developer  | Implements features and fixes bugs                 | Updates status during implementation           |
| Manager    | Oversees projects and approves changes             | Approves, rejects, and closes issues           |
| Reporter   | Reports issues and verifies resolution             | Creates issues and verifies resolution         |

## Workflow Diagrams

### Bug Workflow

```
                  ┌─── Manager ────┐
                  ↓                │
New ───Developer──→ In Progress ───Developer──→ Resolved
 ↑                     │  ↑                       │  ↑
 │                     │  │                       │  │
 └─────────────────────┘  │                       │  │
          Feedback  ←─────┘                       │  │
                                                  │  │
                                                  │  │
Rejected ←─── Manager ────┐                       │  │
                          │                       │  │
                          │                       │  │
                    Feedback ←── Reporter/Manager ┘  │
                          ↑                          │
                          │                          │
                          └───── Reporter/Manager ───┘
                                     Closed
```

### Feature Workflow

```
                  ┌─── Developer/Manager ─┐
                  ↓                       │
New ────────────→ In Progress ──────────→ Resolved
 ↑                     │  ↑                  │  ↑
 │                     │  │                  │  │
 └─────────────────────┘  │                  │  │
          Feedback  ←─────┘                  │  │
                                             │  │
                                             │  │
Rejected ←─── Manager ────┐                  │  │
                          │                  │  │
                          │                  │  │
                    Feedback ←─── Manager ───┘  │
                          ↑                     │
                          │                     │
                          └──────── Manager ────┘
                                     Closed
```

### Support Workflow

```
                  ┌─── Developer/Manager ────┐
                  ↓                          │
New ────────────→ In Progress ──────────────→ Resolved
 ↑   ↓                  │  ↑                    │
 │   │                  │  │                    │
 │   └── Feedback ←─────┘  │                    │
 │        ↑  │             │                    │
 │        │  │             │                    │
 └────────┘  └─────────────┘                    │
                                                │
                                                │
                                                │
                                                │
                                                │
                                          Closed ←── Reporter
```

## Using Workflows in MCP

### Via Web Interface

1. **Viewing an Issue's Current Status**:
   - Open the issue in Redmine
   - Status is displayed in the issue details

2. **Changing Status**:
   - Open the issue
   - Click "Edit"
   - Select a new status from the dropdown (only valid transitions will be shown)
   - Add a note explaining the change
   - Click "Submit"

### Via API

1. **Checking Status**:
   ```
   GET /issues/[id].json
   ```

2. **Updating Status**:
   ```
   PUT /issues/[id].json
   Content-Type: application/json
   X-Redmine-API-Key: your_api_key
   
   {
     "issue": {
       "status_id": [status_id],
       "notes": "Status update reason"
     }
   }
   ```

3. **Getting Available Statuses**:
   ```
   GET /issues/[id]/status.json
   ```

### Via MCP Commands

```
[MCP]
Command: rmcp.issue.transition
Parameters:
  issueId: 123
  status: "In Progress"
  comment: "Starting work on this issue"
[/MCP]
```

## Status Transition Guidelines

### When to Use Each Status

* **New → In Progress**: When work actively begins on the issue
* **In Progress → Feedback**: When information is needed to continue
* **Feedback → In Progress**: When requested information has been provided
* **In Progress → Resolved**: When implementation is complete
* **Resolved → Closed**: When the resolution has been verified
* **Resolved → Feedback**: When the resolution needs changes
* **New → Rejected**: When the issue won't be implemented

### Best Practices

1. **Update Status Promptly**: Change issue status as soon as its actual state changes
2. **Add Meaningful Notes**: Include context when transitioning status
3. **Respect Role Boundaries**: Only transition status if your role permits it
4. **Use Correct Workflows**: Different tracker types may have different workflows
5. **Maintain Status Hygiene**: Don't leave issues in intermediate states for extended periods

## Common Status Transition Patterns

### Bug Resolution

1. Reporter creates bug → **New**
2. Developer starts work → **In Progress**
3. Developer completes fix → **Resolved**
4. Reporter/QA verifies fix → **Closed**

### Feature Implementation

1. Manager creates feature → **New**
2. Developer starts implementation → **In Progress**
3. Developer completes work → **Resolved**
4. Manager reviews and approves → **Closed**

### Support Request

1. User submits request → **New**
2. Support team asks for details → **Feedback**
3. User provides details → **In Progress**
4. Support team resolves issue → **Resolved**
5. User confirms resolution → **Closed**

## Troubleshooting

### Common Issues

1. **Can't transition to a status**: Check if your role has permission
2. **Status missing from dropdown**: Not a valid transition in current workflow
3. **Issue stuck in status**: May need manager intervention

### Getting Help

* For workflow issues: Contact the MCP administrator
* For role permission issues: Contact a manager with admin rights
* For process questions: Refer to the workflow documentation

## Advanced Workflow Topics

### Custom Fields in Workflows

Status transitions can trigger custom field requirements:

* **Required fields**: Must be completed to make transition
* **Read-only fields**: Become locked after certain transitions
* **Visible fields**: Appear depending on status

### Workflow Reports

The MCP implementation includes the following workflow reports:

* **Time in Status**: How long issues remain in each status
* **Transition Counts**: Frequency of status changes
* **Workflow Violations**: Unexpected or manual status changes
* **Bottleneck Analysis**: Where issues get stuck

### Workflow Integration with MCP

The MCP system interfaces with workflows through:

1. **Event triggers**: Status changes can trigger MCP actions
2. **Validation rules**: MCP can enforce workflow compliance
3. **Automation**: MCP can automatically update status based on events

## Conclusion

The workflow system is a critical component of the Redmine MCP implementation. By following these guidelines, teams can ensure consistent process execution, improve visibility into project status, and maintain clear handoffs between team members.
