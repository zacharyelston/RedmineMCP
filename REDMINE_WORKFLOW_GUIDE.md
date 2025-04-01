# Redmine Workflow Guide for RedmineMCP

*Note: Ideally, this file should be in a `docs/` directory.*

This guide provides an overview of how to use Redmine for project management with the RedmineMCP extension.

## Setting Up Redmine Workflow

### Prerequisites
Before establishing a workflow, ensure you have:
1. Created necessary priorities (low, medium, high)
2. Created relevant issue statuses (New, In Progress, Feedback, Resolved, Closed)
3. Created time tracking activities (dev, review, waiting)

### Workflow Steps

A typical Redmine workflow with RedmineMCP follows these steps:

1. **Issue Creation**:
   - Create a new issue with appropriate tracker (Bug, Feature, Support)
   - Assign priority based on impact and urgency
   - Set estimated hours if possible

2. **Issue Assignment**:
   - Assign the issue to a team member
   - Update status to "In Progress"
   - Add watchers for stakeholders who should be notified

3. **Tracking Progress**:
   - Add regular updates via notes
   - Log time spent on activities using appropriate activity types
   - Update percent done as work progresses

4. **Resolving Issues**:
   - Add final notes with resolution details
   - Update status to "Resolved"
   - Request feedback if needed

5. **Closing Issues**:
   - Review the completed work
   - Update status to "Closed"
   - Document any lessons learned

## Best Practices for RedmineMCP Project

1. **Use Standard Naming Conventions**:
   - Issue titles should be clear and concise
   - Follow a standard format: "[Component] Brief description"

2. **Provide Detailed Descriptions**:
   - Include expected behavior, actual behavior, and steps to reproduce for bugs
   - Include user stories and acceptance criteria for features

3. **Link Related Issues**:
   - Use "Related to" or "Blocked by" relationships
   - Reference other issues by ID in comments (#123)

4. **Time Tracking**:
   - Log time regularly, ideally daily
   - Use appropriate activity types to categorize work
   - Compare estimated vs. actual time to improve future estimates

5. **Documentation Updates**:
   - Update relevant documentation when resolving issues
   - Link to documentation in issue notes

## Integration with MCP Extension

The Model Context Protocol (MCP) extension enhances Redmine with AI capabilities:

1. **AI-Assisted Issue Creation**:
   - Use natural language to generate structured issues
   - Let the AI suggest appropriate trackers and priorities

2. **Issue Analysis**:
   - Request AI analysis of complex issues
   - Get suggestions for related issues and potential solutions

3. **Intelligent Updates**:
   - Use natural language to update issues
   - AI will format updates appropriately and update relevant fields

## Common Workflow Scenarios

### Bug Fixing Workflow

1. Bug is reported and prioritized
2. Developer assigns themselves and updates status to "In Progress"
3. Developer logs time while working on the fix
4. Fix is completed, developer updates status to "Resolved"
5. Tester verifies the fix
6. Issue is closed when verified

### Feature Development Workflow

1. Feature is requested and prioritized
2. Feature is assigned to a developer
3. Developer updates status to "In Progress"
4. Regular updates and time logging during development
5. When completed, developer updates status to "Resolved"
6. Project manager or stakeholder reviews the feature
7. Feature is closed after approval

## Reporting

Leverage Redmine's reporting capabilities:
- Use filters to create custom issue lists
- Create saved queries for common reports
- Use the calendar and Gantt chart for timeline visualization
- Export data to CSV for custom analysis
