# Using Notes for Issue Documentation

## Overview

This document explains how to use Redmine issue notes for implementation documentation rather than creating issue-specific directories in the repository.

## Problem

Previously, the project was creating issue-specific directories (e.g., `fixes/issue-XX`) for each issue being worked on, leading to:
- Excessive directory creation
- Organizational complexity
- Difficulty in finding files across multiple issue directories

## Solution

Rather than creating issue-specific directories, we now use Redmine's built-in notes functionality to document implementation details directly within the issue.

## How to Add Notes to an Issue

You can add notes to an issue using the `redmine_issues_update` function with the following parameters:

```javascript
redmine_issues_update({
  issue_id: 123,  // Replace with the actual issue ID
  notes: "## Implementation Status\n\n### Progress\n- [Task 1]: Completed\n- [Task 2]: In progress"
})
```

The notes parameter supports Markdown formatting, allowing for well-structured documentation.

## Note Templates

We've added these templates to the redmine.yaml configuration file for common note types:

### Implementation Plan Template

```markdown
## Implementation Plan

### Overview
[Brief description of the implementation approach]

### Steps
1. [First step]
2. [Second step]
3. [Third step]

### Technical Details
[Any technical details or considerations]

### Dependencies
[List of dependencies or prerequisites]
```

### Implementation Summary Template

```markdown
## Implementation Summary

### Completed Work
[Description of what was implemented]

### Key Decisions
[Important decisions made during implementation]

### Technical Notes
[Technical details about the implementation]

### Testing
[How the implementation was tested]
```

### Status Update Template

```markdown
## Status Update

### Progress
- [Task 1]: Completed
- [Task 2]: In progress (XX% complete)
- [Task 3]: Not started

### Blockers
[Any blockers or issues encountered]

### Next Steps
[What will be worked on next]
```

## Benefits

This approach offers several advantages:

1. **Centralization** - All information about an issue is kept in one place
2. **Simplicity** - No need to create and manage multiple directories and files
3. **Accessibility** - Anyone can view the implementation details directly in the issue
4. **Workflow improvement** - Eliminates repetitive directory creation and file management
5. **Better organization** - Keeps the repository structure clean and focused

## Configuration

We've updated the project configuration to support this approach:

1. Added `file_organization` section to redmine.yaml:
   ```yaml
   file_organization:
     # Disable creation of issue-specific directories
     create_issue_directories: false
     # Use issue notes for implementation details
     use_issue_notes: true
   ```

2. Added guidelines to prompt.yaml:
   ```yaml
   - name: "Proper File Organization"
     description: "Never create issue-specific directories like fixes/issue-XX. 
                  Add implementation details as notes directly to the Redmine issue 
                  whenever possible."
   ```

## Special Note on API Behavior

When adding notes to issues via the Redmine API, note that:

1. The notes are successfully added to the issue (you'll get a success response)
2. However, the notes may not immediately appear in the API response when retrieving the issue with journals
3. You can verify the notes were added by viewing the issue in the Redmine web interface

## Existing Issue Directories

Existing issue-specific directories will be preserved for historical purposes, but all new issues should follow this notes-based approach.
