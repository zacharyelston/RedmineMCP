# Redmine Workflow Best Practices

## Introduction

This document outlines best practices for configuring and using workflows in Redmine for the ModelContextProtocol (MCP) implementation. Well-designed workflows improve team productivity, enhance visibility into project progress, and ensure consistent issue management across teams.

## Workflow Design Principles

### 1. Keep it Simple

- **Start with basic workflows**: Begin with a minimal set of statuses and transitions that cover your essential needs
- **Add complexity gradually**: Only add additional statuses or transitions when there is a clear need
- **Avoid status overload**: Too many statuses can confuse users and complicate reporting
- **Consider the necessary steps**: Every required status should represent a distinct and meaningful state in your process

### 2. Align with Team Structure

- **Match roles to responsibilities**: Configure workflow permissions based on actual team roles
- **Respect team autonomy**: Allow teams to move issues through statuses they control
- **Enforce approval gates**: Use role restrictions for transitions that require specific authority
- **Balance flexibility and control**: Give teams freedom within their domain while maintaining process governance

### 3. Support Visibility

- **Make progress obvious**: Status names should clearly indicate where an issue stands
- **Use consistent terminology**: Status names should mean the same thing across all trackers
- **Facilitate reporting**: Design workflows that produce meaningful metrics and reports
- **Avoid hidden work**: Include statuses that make all work visible, including waiting states

## Standard Workflow Configurations

### Basic Development Workflow

```
New → In Progress → Resolved → Closed
     ↑     ↓     ↑
     └─ Feedback ─┘
```

- **New**: Issue has been created but work hasn't started
- **In Progress**: Active development is underway
- **Feedback**: Additional information or clarification is needed
- **Resolved**: Work is complete but needs verification
- **Closed**: Issue has been verified and completed

### Role Permissions

| Status Transition | Developer | Manager | Reporter |
|-------------------|-----------|---------|----------|
| New → In Progress | ✓         | ✓       |          |
| In Progress → Feedback | ✓         | ✓       |          |
| Feedback → In Progress | ✓         | ✓       |          |
| In Progress → Resolved | ✓         | ✓       |          |
| Resolved → Closed |           | ✓       | ✓        |
| Resolved → Feedback |           | ✓       | ✓        |
| New → Rejected    |           | ✓       |          |

### Tracker-Specific Considerations

#### Bug Workflow

- Should include validation steps (testing/QA)
- May require approval from QA before closing
- Consider severity-based routing

#### Feature Workflow

- May include design and planning statuses
- Often requires stakeholder review
- Typically includes testing phase

#### Support Workflow

- Emphasize quick response and resolution
- Include assignment and triage states
- May need escalation paths

## Workflow Implementation in MCP

### SQL Configuration (Already Implemented)

The current implementation includes:

1. **Issue Statuses**:
   - New, In Progress, Feedback, Resolved, Closed, Rejected

2. **Role-Based Transitions**:
   - Developer can move issues through development states
   - Manager can reject, approve, or close issues
   - Reporter can provide feedback and verify resolutions

3. **Tracker-Specific Workflows**:
   - Bug tracking workflow
   - Feature development workflow
   - Support request workflow
   - Task management workflow
   - Epic and Story workflows for agile methodologies

### API Integration

The MCP system integrates with these workflows through:

1. **Status Transition API**:
   - `PUT /issues/{id}.json` with `status_id` parameter

2. **Role-Based Authorization**:
   - API checks are enforced based on user roles

3. **Workflow Query**:
   - Available transitions can be queried through the API

## Workflow Usage Guidelines

### For Developers

- Update issue status promptly when work begins and ends
- Use the Feedback status when blocking information is needed
- Document important details when transitioning to Resolved

### For Managers

- Review Resolved issues regularly and close or provide feedback
- Use Rejected status sparingly and with clear explanation
- Monitor workflow metrics to identify process bottlenecks

### For Reporters

- Provide thorough information to minimize Feedback cycles
- Verify Resolved issues promptly
- Use the correct issue tracker type for new issues

## Common Workflow Patterns

### Sequential Workflow

Good for predictable processes with clear steps:

```
New → Planning → In Progress → Testing → Resolved → Closed
```

### Parallel Workflow

Useful for issues that have concurrent work streams:

```
           ┌→ Dev Review →┐
New → In Progress         Integration → Resolved → Closed
           └→ QA Review  →┘
```

### Approval Workflow

Important for processes requiring explicit sign-off:

```
New → In Progress → Resolved → Approval → Closed
```

## Measuring Workflow Effectiveness

- **Cycle Time**: Time from New to Closed
- **Lead Time**: Time from creation to delivery
- **Time in Status**: Duration spent in each status
- **Transition Frequency**: How often issues move back and forth between statuses
- **First-time Resolution Rate**: Issues closed without returning to previous statuses

## Common Workflow Anti-Patterns

- **Eternal In Progress**: Issues stay in progress indefinitely
- **Status Limbo**: Issues get stuck in intermediate statuses
- **Rubber Stamping**: Approvals that happen automatically without review
- **Process Overhead**: Too many required statuses for simple issues
- **Role Mismatch**: Permissions don't align with actual responsibilities

## Conclusion

A well-designed workflow system is critical for effective project management in Redmine. The MCP implementation provides a comprehensive workflow configuration that balances flexibility and structure. By following these best practices, teams can ensure consistent process execution while maintaining the agility needed for effective software development.

## References

- Redmine Workflow Documentation
- Agile Project Management Best Practices
- ITIL Service Management Framework
- MCP Implementation Guidelines
