-- fix_all_trackers.sql
-- Script to fix all trackers missing default_status_id
-- Part of the ModelContextProtocol (MCP) Implementation

-- First check the current status
SELECT id, name, default_status_id 
FROM trackers;

-- Update all trackers to use 'New' as the default status
UPDATE trackers 
SET default_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
WHERE default_status_id IS NULL OR default_status_id = '';

-- Verify the update worked
SELECT id, name, default_status_id 
FROM trackers;
