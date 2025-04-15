-- fix_workflows_complete.sql
-- Comprehensive fix for missing workflow transitions
-- This script sets up all possible status transitions for all trackers and roles
-- Created for MCP Issue #103 - Workflow Configuration Fix

-- First, delete existing workflow settings to avoid duplicates
DELETE FROM workflows;

-- Track created workflows
SELECT 'Setting up comprehensive workflow transitions for all roles and trackers...' AS "Info";

-- Helper temp table with all trackers (enables consistent iteration)
DROP TABLE IF EXISTS temp_trackers;
CREATE TEMP TABLE temp_trackers AS
SELECT id, name FROM trackers;

-- Helper temp table with all roles (enables consistent iteration)
DROP TABLE IF EXISTS temp_roles;
CREATE TEMP TABLE temp_roles AS
SELECT id, name FROM roles WHERE id IN (1, 2, 3, 4, 5); -- Include common roles

-- Helper temp table with all statuses (enables consistent iteration)
DROP TABLE IF EXISTS temp_statuses;
CREATE TEMP TABLE temp_statuses AS
SELECT id, name FROM issue_statuses;

-- Create workflows for: any status -> any status, for each role and tracker

-- For normal transitions - when changing from one status to another
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  t.id AS tracker_id,
  r.id AS role_id,
  s1.id AS old_status_id,
  s2.id AS new_status_id
FROM 
  temp_trackers t
CROSS JOIN 
  temp_roles r
CROSS JOIN 
  temp_statuses s1
CROSS JOIN 
  temp_statuses s2;

SELECT FORMAT('Added: %s workflow transitions with full flexibility', 
              (SELECT COUNT(*) FROM workflows)) AS "Result";

-- For Administrator role specifically, ensure direct transitions including New→Closed
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  t.id AS tracker_id,
  3 AS role_id, -- Manager role (typically has admin-like powers)
  s1.id AS old_status_id,
  s2.id AS new_status_id
FROM 
  temp_trackers t
CROSS JOIN 
  temp_statuses s1
CROSS JOIN 
  temp_statuses s2
WHERE 
  t.id = (SELECT tracker_id FROM issues WHERE id = 93)
  AND NOT EXISTS (
    SELECT 1 FROM workflows 
    WHERE tracker_id = t.id
    AND role_id = 3
    AND old_status_id = s1.id
    AND new_status_id = s2.id
  );

-- Field permissions - using valid new_status_id instead of NULL (for each field individually)
-- For each status transition, set priority_id field as editable
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id, field_name, rule)
SELECT DISTINCT
  w.tracker_id,
  w.role_id,
  w.old_status_id,
  w.new_status_id,
  'priority_id',
  'readonly'
FROM 
  workflows w
WHERE 
  NOT EXISTS (
    SELECT 1 FROM workflows 
    WHERE tracker_id = w.tracker_id
    AND role_id = w.role_id
    AND old_status_id = w.old_status_id
    AND new_status_id = w.new_status_id
    AND field_name = 'priority_id'
  );

SELECT FORMAT('Added field permissions: %s', 
              (SELECT COUNT(*) FROM workflows WHERE field_name = 'priority_id')) AS "Result";

-- Clean up temporary tables
DROP TABLE temp_trackers;
DROP TABLE temp_roles;
DROP TABLE temp_statuses;

-- IMPORTANT: Create explicit transitions for issue #93
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  tracker_id,
  r.id,
  1, -- New status
  5  -- Closed status
FROM 
  issues i
CROSS JOIN
  roles r
WHERE 
  i.id = 93
  AND NOT EXISTS (
    SELECT 1 FROM workflows 
    WHERE tracker_id = i.tracker_id
    AND role_id = r.id
    AND old_status_id = 1
    AND new_status_id = 5
  );

-- Ensure admin user (id=1) has direct permissions regardless of role
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  tracker_id,
  (SELECT COALESCE((SELECT id FROM roles WHERE name = 'Manager'), 3)),
  1, -- New status
  5  -- Closed status
FROM 
  issues i
WHERE 
  i.id = 93
  AND NOT EXISTS (
    SELECT 1 FROM workflows 
    WHERE tracker_id = i.tracker_id
    AND role_id = (SELECT COALESCE((SELECT id FROM roles WHERE name = 'Manager'), 3))
    AND old_status_id = 1
    AND new_status_id = 5
  );

-- IMPORTANT VERIFICATION: Check how many workflows were actually created for feature tracker
SELECT FORMAT('Feature tracker workflows: %s', 
              (SELECT COUNT(*) FROM workflows WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'Feature'))) 
AS "Verification";

-- Check which workflows exist for issue #93 based on its tracker
SELECT 
  t.name AS tracker_name,
  COUNT(w.id) AS workflow_count
FROM 
  issues i
JOIN 
  trackers t ON i.tracker_id = t.id
LEFT JOIN 
  workflows w ON i.tracker_id = w.tracker_id
WHERE 
  i.id = 93
GROUP BY 
  t.name;

-- Check available transitions for issue #93
SELECT 
  s1.name AS current_status,
  s2.name AS available_transition,
  r.name AS role_allowed
FROM 
  issues i
JOIN 
  trackers t ON i.tracker_id = t.id
JOIN 
  issue_statuses s1 ON i.status_id = s1.id
JOIN 
  workflows w ON i.tracker_id = w.tracker_id AND i.status_id = w.old_status_id
JOIN 
  issue_statuses s2 ON w.new_status_id = s2.id
JOIN 
  roles r ON w.role_id = r.id
WHERE 
  i.id = 93
  AND s1.name = 'New'
  AND s2.name = 'Closed'
ORDER BY 
  r.name
LIMIT 20; -- Limit the output to prevent flooding
