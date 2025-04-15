-- fix_trackers.sql
-- Script to fix the trackers missing default_status_id
-- Part of the ModelContextProtocol (MCP) Implementation

-- First check if the trackers are missing the default_status_id
SELECT id, name, default_status_id 
FROM trackers 
WHERE default_status_id IS NULL;

-- Get the ID of the 'New' status to use as default
SELECT id, name FROM issue_statuses WHERE name = 'New';

-- Update the MCP Documentation tracker to use 'New' as the default status
UPDATE trackers 
SET default_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
WHERE name = 'MCP Documentation' AND default_status_id IS NULL;

-- Update the MCP Test Case tracker to use 'New' as the default status
UPDATE trackers 
SET default_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
WHERE name = 'MCP Test Case' AND default_status_id IS NULL;

-- Verify the update worked
SELECT id, name, default_status_id 
FROM trackers;
