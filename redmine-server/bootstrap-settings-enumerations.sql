-- bootstrap-settings-enumerations.sql
-- This script sets up all the necessary settings and enumerations for Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- ENUMERATIONS

-- Create/update priority enumeration (IssuePriority)
DELETE FROM enumerations WHERE type = 'IssuePriority';
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('Low', 1, 'IssuePriority', FALSE, TRUE),
('Normal', 2, 'IssuePriority', TRUE, TRUE),
('High', 3, 'IssuePriority', FALSE, TRUE),
('Urgent', 4, 'IssuePriority', FALSE, TRUE),
('Immediate', 5, 'IssuePriority', FALSE, TRUE);

-- Create/update activity enumeration (TimeEntryActivity)
DELETE FROM enumerations WHERE type = 'TimeEntryActivity';
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('Design', 1, 'TimeEntryActivity', FALSE, TRUE),
('Development', 2, 'TimeEntryActivity', TRUE, TRUE),
('Testing', 3, 'TimeEntryActivity', FALSE, TRUE),
('Documentation', 4, 'TimeEntryActivity', FALSE, TRUE),
('Management', 5, 'TimeEntryActivity', FALSE, TRUE),
('Requirements', 6, 'TimeEntryActivity', FALSE, TRUE),
('Deployment', 7, 'TimeEntryActivity', FALSE, TRUE),
('Support', 8, 'TimeEntryActivity', FALSE, TRUE);

-- Create/update document category enumeration (DocumentCategory)
DELETE FROM enumerations WHERE type = 'DocumentCategory';
INSERT INTO enumerations (name, position, type, is_default, active)
VALUES 
('User', 1, 'DocumentCategory', FALSE, TRUE),
('Technical', 2, 'DocumentCategory', TRUE, TRUE),
('Administrative', 3, 'DocumentCategory', FALSE, TRUE),
('Specification', 4, 'DocumentCategory', FALSE, TRUE),
('Architecture', 5, 'DocumentCategory', FALSE, TRUE),
('Design', 6, 'DocumentCategory', FALSE, TRUE);

-- SETTINGS

-- User management settings
DELETE FROM settings WHERE name IN (
  'login_required', 'autologin', 'self_registration', 'unsubscribe',
  'password_min_length', 'password_max_age', 'lost_password', 'twofa',
  'rest_api_enabled'
);
INSERT INTO settings (name, value, updated_on)
VALUES 
('login_required', '0', NOW()),
('autologin', '7', NOW()),
('self_registration', '1', NOW()),
('unsubscribe', '1', NOW()),
('password_min_length', '8', NOW()),
('password_max_age', '0', NOW()),
('lost_password', '1', NOW()),
('twofa', '0', NOW()),
('rest_api_enabled', '1', NOW());

-- Issue tracking settings
DELETE FROM settings WHERE name IN (
  'issue_done_ratio', 'non_working_week_days', 'issue_list_default_columns',
  'default_issue_query', 'cross_project_issue_relations',
  'allow_issue_assignment_to_groups', 'show_status_changes_in_mail_subject',
  'issue_group_assignment'
);
INSERT INTO settings (name, value, updated_on)
VALUES 
('issue_done_ratio', 'issue_field', NOW()),
('non_working_week_days', '---
- "6"
- "7"
', NOW()),
('issue_list_default_columns', '---
- tracker
- status
- priority
- subject
- assigned_to
- updated_on
', NOW()),
('default_issue_query', NULL, NOW()),
('cross_project_issue_relations', '1', NOW()),
('allow_issue_assignment_to_groups', '0', NOW()),
('show_status_changes_in_mail_subject', '0', NOW()),
('issue_group_assignment', '0', NOW());

-- Project settings
DELETE FROM settings WHERE name IN (
  'default_projects_modules', 'sequential_project_identifiers',
  'project_list_defaults', 'default_projects_tracker_ids',
  'repositories_encodings', 'sys_api_enabled', 'enabled_scm'
);
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

-- MCP specific settings
DELETE FROM settings WHERE name IN (
  'app_title', 'welcome_text', 'per_page_options', 'search_results_per_page',
  'mail_from', 'mail_handler_api_key', 'emails_footer', 'host_name',
  'protocol', 'text_formatting'
);
INSERT INTO settings (name, value, updated_on)
VALUES 
('app_title', 'Redmine MCP Server', NOW()),
('welcome_text', 'Welcome to the ModelContextProtocol (MCP) Redmine Server.

This Redmine instance is configured to work with the MCP system for consistent project management.', NOW()),
('per_page_options', '25,50,100', NOW()),
('search_results_per_page', '10', NOW()),
('mail_from', 'redmine-mcp@example.com', NOW()),
('mail_handler_api_key', '7a4ed5c91b405d30fda60909dbc86c2651c38217', NOW()),
('emails_footer', '-- 
ModelContextProtocol (MCP) Redmine Server
', NOW()),
('host_name', 'localhost:3000', NOW()),
('protocol', 'http', NOW()),
('text_formatting', 'textile', NOW());

-- Display settings
DELETE FROM settings WHERE name IN (
  'ui_theme', 'default_language', 'start_of_week', 'date_format',
  'time_format', 'timespan_format', 'users_format', 'thumbnail_size',
  'gravatar_enabled', 'gravatar_default', 'wiki_compression',
  'max_image_file_size', 'max_attachment_size', 'diff_max_lines_displayed'
);
INSERT INTO settings (name, value, updated_on)
VALUES 
('ui_theme', '', NOW()),
('default_language', 'en', NOW()),
('start_of_week', '1', NOW()),
('date_format', '', NOW()),
('time_format', '%H:%M', NOW()),
('timespan_format', 'decimal', NOW()),
('users_format', 'firstname_lastname', NOW()),
('thumbnail_size', '100', NOW()),
('gravatar_enabled', '0', NOW()),
('gravatar_default', 'wavatar', NOW()),
('wiki_compression', '', NOW()),
('max_image_file_size', '300', NOW()),
('max_attachment_size', '5120', NOW()),
('diff_max_lines_displayed', '1500', NOW());

-- Additional trackers specifically for MCP
INSERT INTO trackers (name, position, is_in_roadmap, fields_bits)
VALUES 
('Task', 4, TRUE, 0),
('Epic', 5, TRUE, 0),
('Story', 6, TRUE, 0)
ON CONFLICT (id) DO NOTHING;

-- Print confirmation
SELECT 'Redmine settings and enumerations have been bootstrapped for MCP' AS result;
