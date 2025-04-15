-- fix_all_trackers_v2.sql
-- Script to fix all trackers missing default_status_id
-- Part of the ModelContextProtocol (MCP) Implementation

-- First check the current status with more detail
SELECT id, name, COALESCE(default_status_id::text, 'NULL') as default_status_id,
       pg_typeof(default_status_id) as column_type
FROM trackers;

-- Update all trackers to use 'New' as the default status - only those without a value
UPDATE trackers 
SET default_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
WHERE default_status_id IS NULL;

-- Update the built-in trackers specifically by ID
UPDATE trackers 
SET default_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
WHERE id IN (1, 2, 3);

-- Verify the update worked
SELECT id, name, default_status_id 
FROM trackers;
