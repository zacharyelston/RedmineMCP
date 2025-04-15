-- diagnose_issue_creation.sql
-- Script to diagnose issues with issue creation in Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- Get project information
SELECT id, name, identifier 
FROM projects 
WHERE identifier = 'mcp-project';

-- Get trackers information
SELECT id, name, default_status_id
FROM trackers
ORDER BY position;

-- Get issue statuses
SELECT id, name, is_closed
FROM issue_statuses
ORDER BY position;

-- Get priorities (enumerations table)
SELECT id, name, position, type
FROM enumerations
WHERE type = 'IssuePriority'
ORDER BY position;

-- Get required and available fields for issues
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'issues'
ORDER BY ordinal_position;

-- Check if there are any issues at all in the database
SELECT COUNT(*) as issue_count FROM issues;

-- Check if there are any custom fields that might be required
SELECT id, name, field_format, is_required
FROM custom_fields
WHERE type = 'IssueCustomField';

-- Check if project has any modules enabled (particularly issue tracking)
SELECT em.name
FROM projects p
JOIN enabled_modules em ON p.id = em.project_id
WHERE p.identifier = 'mcp-project';
