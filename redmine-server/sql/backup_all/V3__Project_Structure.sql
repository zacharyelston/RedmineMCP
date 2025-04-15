-- V3__Project_Structure.sql
-- Project structure for Redmine PostgreSQL database
-- This migration sets up trackers, issue statuses, and project modules

-- Create default trackers
INSERT INTO trackers (name, position, is_in_roadmap, fields_bits)
VALUES 
('Bug', 1, FALSE, 0),
('Feature', 2, TRUE, 0),
('Support', 3, FALSE, 0);

-- Create issue statuses
INSERT INTO issue_statuses (name, is_closed, position)
VALUES 
('New', FALSE, 1),
('In Progress', FALSE, 2),
('Resolved', FALSE, 3),
('Feedback', FALSE, 4),
('Closed', TRUE, 5),
('Rejected', TRUE, 6);

-- Create workflow connections between trackers, statuses, and roles
-- Manager role (id=1) can move issues through all states
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 1, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns;

-- Developer role (id=2) workflow
-- From 'New' to 'In Progress', 'Resolved', 'Feedback'
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 2, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns
WHERE os.name = 'New' AND ns.name IN ('In Progress', 'Resolved', 'Feedback');

-- From 'In Progress' to 'Resolved', 'Feedback'
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 2, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns
WHERE os.name = 'In Progress' AND ns.name IN ('Resolved', 'Feedback');

-- From 'Resolved' to 'In Progress', 'Closed'
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 2, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns
WHERE os.name = 'Resolved' AND ns.name IN ('In Progress', 'Closed');

-- From 'Feedback' to 'In Progress', 'Resolved', 'Closed'
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 2, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns
WHERE os.name = 'Feedback' AND ns.name IN ('In Progress', 'Resolved', 'Closed');

-- Reporter role (id=3) can only create new issues and move them to feedback
INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, author, assignee)
SELECT t.id, os.id, ns.id, 3, FALSE, FALSE
FROM trackers t, issue_statuses os, issue_statuses ns
WHERE (os.name = 'New' AND ns.name = 'Feedback');

-- Create priority enumeration (IssuePriority)
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('Low', 1, 'IssuePriority', FALSE, TRUE),
('Normal', 2, 'IssuePriority', TRUE, TRUE),
('High', 3, 'IssuePriority', FALSE, TRUE),
('Urgent', 4, 'IssuePriority', FALSE, TRUE),
('Immediate', 5, 'IssuePriority', FALSE, TRUE);

-- Create activity enumeration (TimeEntryActivity)
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('Design', 1, 'TimeEntryActivity', FALSE, TRUE),
('Development', 2, 'TimeEntryActivity', TRUE, TRUE),
('Testing', 3, 'TimeEntryActivity', FALSE, TRUE),
('Documentation', 4, 'TimeEntryActivity', FALSE, TRUE),
('Management', 5, 'TimeEntryActivity', FALSE, TRUE);

-- Create document category enumeration (DocumentCategory)
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('User', 1, 'DocumentCategory', FALSE, TRUE),
('Technical', 2, 'DocumentCategory', TRUE, TRUE),
('Administrative', 3, 'DocumentCategory', FALSE, TRUE);

-- Set up default settings
INSERT INTO settings (name, value, updated_on)
VALUES 
('default_projects_modules', '---
- issue_tracking
- time_tracking
- news
- documents
- files
- wiki
- repository
- boards
- calendar
- gantt
', NOW()),
('sequential_project_identifiers', '0', NOW()),
('project_list_defaults', '---
:column_names:
- name
- identifier
- short_description
- is_public
- created_on
:filters:
  status: "1"
:sort:
- name
:sort_direction:
- asc
', NOW()),
('default_projects_tracker_ids', '---
- 1
- 2
- 3
', NOW()),
('repositories_encodings', 'UTF-8,CP1250,CP1251,CP1252,ISO-8859-1,ISO-8859-2,ISO-8859-3,ISO-8859-4,ISO-8859-5,ISO-8859-6,ISO-8859-7,ISO-8859-8,ISO-8859-9,ISO-8859-13,ISO-8859-15,Big5,GB18030,EUC-JP,ISO-2022-JP,Shift_JIS,KOI8-R,CP866,EUC-KR,Windows-1250,Windows-1251,Windows-1252,Windows-1253,Windows-1254,Windows-1255,Windows-1256,Windows-1257,Windows-1258,UTF-16,UTF-16LE,UTF-16BE',
NOW()),
('sys_api_enabled', '0', NOW()),
('enabled_scm', '---
- Subversion
- Git
', NOW());
