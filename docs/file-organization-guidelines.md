# File Organization Guidelines

## Overview

This document outlines the guidelines for file organization within the redmine-mcp project, with a particular focus on how to handle issue-related files.

## Problem Addressed

Previously, the project had a pattern of creating issue-specific directories (e.g., `fixes/issue-XX`) for each issue being worked on. This approach led to:

1. Excessive directory creation
2. Organizational complexity 
3. Difficulty in finding files across multiple issue directories
4. Repetitive, wasteful processes

## New Guidelines

As of April 15, 2025, the following changes have been implemented:

1. The creation of issue-specific directories (`fixes/issue-XX`) is now **disabled**
2. **Implementation details should be added as notes directly to the Redmine issue**
3. For any necessary files, they should be stored directly in appropriate locations with descriptive filenames
4. Filenames should include the issue number for easy reference (e.g., `implementation-plan-issue-93.md`)
5. Existing issue directories will be preserved for historical purposes

## Configuration Changes

These guidelines have been implemented through the following changes:

1. Added `file_organization` configuration in `redmine.yaml`:
   - Set `create_issue_directories: false` to disable creation of issue-specific directories
   - Defined `issue_files_pattern: "{file_type}-issue-{issue_number}.md"` for consistent naming
   - Set `existing_issue_directories: "preserve"` to maintain historical organization

2. Updated best practices in `prompt.yaml`:
   - Added explicit guidance against creating issue-specific directories
   - Added proper file organization to the MCP best practices

## Implementation

When working on issues, follow these practices:

1. **Add implementation plans, summaries, status updates, and other notes directly to the issue in Redmine**
   - Use the `redmine_issues_update` function with the `notes` parameter
   - Format notes with clear headings and sections using Markdown
   - Update the issue with progress notes as you work

2. For any documents that must be stored as separate files:
   - Store implementation plans as `implementation-plan-issue-XX.md` directly in an appropriate directory
   - Store implementation summaries as `implementation-summary-issue-XX.md` directly in an appropriate directory
   - Store PR descriptions as `pr-description-issue-XX.md` directly in an appropriate directory
   - Store status reports as `status-report-issue-XX.md` directly in an appropriate directory

## Benefits

This new approach provides several benefits:

1. **Keeps all implementation details directly in the issue**
   - Centralizes all information about an issue in one place
   - Makes it easy to track progress and decisions
   - Removes the need for cross-referencing between issues and files
   - Ensures issue history and implementation details stay together

2. For any necessary files:
   - Reduced clutter and unnecessary directory creation
   - Simpler, flatter file structure for easier navigation
   - Consistent naming conventions for easier file location
   - Streamlined workflow without repetitive directory creation
   - Improved file organization and project management

## Future Considerations

While existing issue directories will be preserved for historical purposes, a future cleanup effort could reorganize these files according to the new structure to ensure complete consistency across the project.
