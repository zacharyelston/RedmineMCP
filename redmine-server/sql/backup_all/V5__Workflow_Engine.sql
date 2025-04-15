-- V5__Workflow_Engine.sql
-- Workflow engine setup for Redmine PostgreSQL database
-- This migration configures additional workflow rules and transitions

-- Create workflow transitions for field changes
-- Field visibility rules for all tracker/role/status combinations

-- Allow editing of priority field in all statuses for all roles
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'priority_id', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update priority field to be editable for Manager and Developer roles
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name = 'priority_id' 
AND role_id IN (
  SELECT id FROM roles WHERE name IN ('Manager', 'Developer')
);

-- Allow editing of assigned_to field for Manager role
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'assigned_to_id', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update assigned_to field to be editable for Manager role
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name = 'assigned_to_id' 
AND role_id IN (
  SELECT id FROM roles WHERE name = 'Manager'
);

-- Allow editing of target version for Manager role
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'fixed_version_id', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update target version field to be editable for Manager role
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name = 'fixed_version_id' 
AND role_id IN (
  SELECT id FROM roles WHERE name = 'Manager'
);

-- Set up workflow permissions for done_ratio field
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'done_ratio', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update done_ratio field to be editable for Manager and Developer roles
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name = 'done_ratio' 
AND role_id IN (
  SELECT id FROM roles WHERE name IN ('Manager', 'Developer')
);

-- Set up workflow permissions for estimated_hours field
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'estimated_hours', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update estimated_hours field to be editable for Manager and Developer roles
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name = 'estimated_hours' 
AND role_id IN (
  SELECT id FROM roles WHERE name IN ('Manager', 'Developer')
);

-- Set up workflow permissions for start_date and due_date fields
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'start_date', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, type, field_name, rule)
SELECT t.id, s.id, s.id, r.id, 'WorkflowPermission', 'due_date', 'readonly'
FROM trackers t, issue_statuses s, roles r
WHERE r.builtin = 0;

-- Update date fields to be editable for Manager role
UPDATE workflows 
SET rule = 'enabled'
WHERE field_name IN ('start_date', 'due_date') 
AND role_id IN (
  SELECT id FROM roles WHERE name = 'Manager'
);

-- Add special rule allowing issue authors to change status from New to Feedback
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author)
SELECT t.id, os.id, ns.id, r.id, TRUE
FROM trackers t, issue_statuses os, issue_statuses ns, roles r
WHERE os.name = 'New' AND ns.name = 'Feedback' AND r.name = 'Reporter';

-- Add special rule allowing issue assignees to resolve their issues
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, assignee)
SELECT t.id, os.id, ns.id, r.id, TRUE
FROM trackers t, issue_statuses os, issue_statuses ns, roles r
WHERE os.name = 'In Progress' AND ns.name = 'Resolved' AND r.name = 'Developer';

-- Special workflow rules for Bug tracker
-- All bugs marked as Resolved must go through Feedback before Closed
DELETE FROM workflows 
WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'Bug')
AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'Resolved')
AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Closed');

-- Special workflow rules for Support tracker
-- Add status transition from any status to Rejected for Manager role
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'Support'),
  os.id,
  (SELECT id FROM issue_statuses WHERE name = 'Rejected'),
  (SELECT id FROM roles WHERE name = 'Manager')
FROM issue_statuses os
WHERE os.name != 'Rejected';

-- Setup workflow settings
INSERT INTO settings (name, value, updated_on)
VALUES 
('issue_status_change_journal_field', '1', NOW());
