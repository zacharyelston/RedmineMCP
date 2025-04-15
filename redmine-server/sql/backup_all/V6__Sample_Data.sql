-- V6__Sample_Data.sql
-- Sample data for Redmine PostgreSQL database
-- This migration adds test data for functional testing

-- Sample projects
INSERT INTO projects (name, description, identifier, status, is_public, created_on, updated_on, lft, rgt, inherit_members)
VALUES 
('MCP Development', 'ModelContextProtocol development project for Redmine integration', 'mcp-dev', 1, TRUE, NOW(), NOW(), 1, 2, FALSE),
('API Testing', 'Project for testing API functionality and integration', 'api-test', 1, TRUE, NOW(), NOW(), 3, 4, FALSE),
('Documentation', 'Redmine documentation and user guides', 'docs', 1, TRUE, NOW(), NOW(), 5, 6, FALSE);

-- Enable modules for all projects
INSERT INTO enabled_modules (project_id, name)
SELECT p.id, m.module_name
FROM projects p, 
     (SELECT 'issue_tracking' AS module_name UNION
      SELECT 'time_tracking' UNION
      SELECT 'news' UNION
      SELECT 'documents' UNION
      SELECT 'files' UNION
      SELECT 'wiki' UNION
      SELECT 'repository' UNION
      SELECT 'boards' UNION
      SELECT 'calendar' UNION
      SELECT 'gantt') m;

-- Associate all trackers with all projects
INSERT INTO projects_trackers (project_id, tracker_id)
SELECT p.id, t.id
FROM projects p, trackers t;

-- Create project memberships
-- MCP Development project - all users are members
INSERT INTO members (user_id, project_id, created_on)
SELECT u.id, p.id, NOW()
FROM users u, projects p
WHERE u.type = 'User' AND p.identifier = 'mcp-dev' AND u.login != 'admin';

-- API Testing project - developer and manager
INSERT INTO members (user_id, project_id, created_on)
SELECT u.id, p.id, NOW()
FROM users u, projects p
WHERE u.login IN ('developer', 'manager') AND p.identifier = 'api-test';

-- Documentation project - all except developer
INSERT INTO members (user_id, project_id, created_on)
SELECT u.id, p.id, NOW()
FROM users u, projects p
WHERE u.login IN ('testuser', 'manager') AND p.identifier = 'docs';

-- Assign roles to members
-- Admin as Manager on all projects
INSERT INTO member_roles (member_id, role_id)
SELECT m.id, r.id
FROM members m, roles r, users u, projects p
WHERE m.user_id = u.id AND u.login = 'admin' 
  AND m.project_id = p.id AND r.name = 'Manager';

-- Developer as Developer on all assigned projects
INSERT INTO member_roles (member_id, role_id)
SELECT m.id, r.id
FROM members m, roles r, users u
WHERE m.user_id = u.id AND u.login = 'developer' AND r.name = 'Developer';

-- Test user as Reporter on assigned projects
INSERT INTO member_roles (member_id, role_id)
SELECT m.id, r.id
FROM members m, roles r, users u
WHERE m.user_id = u.id AND u.login = 'testuser' AND r.name = 'Reporter';

-- Manager as Manager on assigned projects
INSERT INTO member_roles (member_id, role_id)
SELECT m.id, r.id
FROM members m, roles r, users u
WHERE m.user_id = u.id AND u.login = 'manager' AND r.name = 'Manager';

-- Create issue categories
INSERT INTO issue_categories (project_id, name, assigned_to_id)
VALUES
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  'Core',
  (SELECT id FROM users WHERE login = 'developer')
),
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  'UI',
  (SELECT id FROM users WHERE login = 'developer')
),
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  'Documentation',
  (SELECT id FROM users WHERE login = 'manager')
),
(
  (SELECT id FROM projects WHERE identifier = 'api-test'),
  'Functionality',
  (SELECT id FROM users WHERE login = 'developer')
),
(
  (SELECT id FROM projects WHERE identifier = 'api-test'),
  'Security',
  (SELECT id FROM users WHERE login = 'manager')
),
(
  (SELECT id FROM projects WHERE identifier = 'docs'),
  'User Guide',
  (SELECT id FROM users WHERE login = 'manager')
);

-- Create versions
INSERT INTO versions (project_id, name, description, status, sharing, created_on, updated_on)
VALUES
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  '1.0',
  'Initial release',
  'open',
  'none',
  NOW(),
  NOW()
),
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  '1.1',
  'First maintenance release',
  'open',
  'none',
  NOW(),
  NOW()
),
(
  (SELECT id FROM projects WHERE identifier = 'api-test'),
  '0.5',
  'Beta release',
  'open',
  'none',
  NOW(),
  NOW()
);

-- Create custom field for testing purposes
INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple)
VALUES
(
  'IssueCustomField',
  'Testing Environment',
  'list',
  FALSE,
  TRUE,
  TRUE,
  1,
  TRUE,
  TRUE,
  TRUE,
  FALSE
);

-- Associate custom field with all trackers
INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
SELECT 
  (SELECT id FROM custom_fields WHERE name = 'Testing Environment'),
  id
FROM trackers;

-- Create sample issues
-- MCP Development - Core issue (Bug)
INSERT INTO issues (
  tracker_id, project_id, subject, description, status_id, priority_id, 
  author_id, assigned_to_id, created_on, updated_on, start_date, due_date,
  category_id, fixed_version_id
)
VALUES (
  (SELECT id FROM trackers WHERE name = 'Bug'),
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  'Protocol Error Handling Not Working',
  'The error handling in the MCP protocol is not working correctly. When an invalid message is received, the server crashes instead of returning an error message.',
  (SELECT id FROM issue_statuses WHERE name = 'New'),
  (SELECT id FROM enumerations WHERE name = 'High' AND type = 'IssuePriority'),
  (SELECT id FROM users WHERE login = 'testuser'),
  (SELECT id FROM users WHERE login = 'developer'),
  NOW(), 
  NOW(),
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days',
  (SELECT id FROM issue_categories WHERE name = 'Core'),
  (SELECT id FROM versions WHERE name = '1.0' AND project_id = (SELECT id FROM projects WHERE identifier = 'mcp-dev'))
);

-- MCP Development - Feature request
INSERT INTO issues (
  tracker_id, project_id, subject, description, status_id, priority_id, 
  author_id, assigned_to_id, created_on, updated_on, start_date, due_date,
  category_id, fixed_version_id
)
VALUES (
  (SELECT id FROM trackers WHERE name = 'Feature'),
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  'Add Authentication Support to Protocol',
  'We need to add authentication support to the MCP protocol to secure communications between Claude and Redmine.',
  (SELECT id FROM issue_statuses WHERE name = 'In Progress'),
  (SELECT id FROM enumerations WHERE name = 'Normal' AND type = 'IssuePriority'),
  (SELECT id FROM users WHERE login = 'manager'),
  (SELECT id FROM users WHERE login = 'developer'),
  NOW() - INTERVAL '2 days', 
  NOW(),
  CURRENT_DATE - INTERVAL '2 days',
  CURRENT_DATE + INTERVAL '14 days',
  (SELECT id FROM issue_categories WHERE name = 'Core'),
  (SELECT id FROM versions WHERE name = '1.1' AND project_id = (SELECT id FROM projects WHERE identifier = 'mcp-dev'))
);

-- API Testing - Bug
INSERT INTO issues (
  tracker_id, project_id, subject, description, status_id, priority_id, 
  author_id, created_on, updated_on
)
VALUES (
  (SELECT id FROM trackers WHERE name = 'Bug'),
  (SELECT id FROM projects WHERE identifier = 'api-test'),
  'API Returning 500 on Large Requests',
  'When sending large requests to the API (over 1MB), it returns a 500 error instead of processing the request.',
  (SELECT id FROM issue_statuses WHERE name = 'New'),
  (SELECT id FROM enumerations WHERE name = 'Urgent' AND type = 'IssuePriority'),
  (SELECT id FROM users WHERE login = 'manager'),
  NOW() - INTERVAL '1 day', 
  NOW()
);

-- Documentation - Support request
INSERT INTO issues (
  tracker_id, project_id, subject, description, status_id, priority_id, 
  author_id, assigned_to_id, created_on, updated_on, category_id
)
VALUES (
  (SELECT id FROM trackers WHERE name = 'Support'),
  (SELECT id FROM projects WHERE identifier = 'docs'),
  'Need Help with API Documentation',
  'I need help understanding how to document the API for the MCP protocol.',
  (SELECT id FROM issue_statuses WHERE name = 'Feedback'),
  (SELECT id FROM enumerations WHERE name = 'Normal' AND type = 'IssuePriority'),
  (SELECT id FROM users WHERE login = 'testuser'),
  (SELECT id FROM users WHERE login = 'manager'),
  NOW() - INTERVAL '3 days', 
  NOW(),
  (SELECT id FROM issue_categories WHERE name = 'User Guide')
);

-- Add custom field values
INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
VALUES
(
  'Issue',
  (SELECT id FROM issues WHERE subject = 'Protocol Error Handling Not Working'),
  (SELECT id FROM custom_fields WHERE name = 'Testing Environment'),
  'Production'
),
(
  'Issue',
  (SELECT id FROM issues WHERE subject = 'Add Authentication Support to Protocol'),
  (SELECT id FROM custom_fields WHERE name = 'Testing Environment'),
  'Development'
),
(
  'Issue',
  (SELECT id FROM issues WHERE subject = 'API Returning 500 on Large Requests'),
  (SELECT id FROM custom_fields WHERE name = 'Testing Environment'),
  'Staging'
);

-- Add some time entries
INSERT INTO time_entries (
  project_id, user_id, issue_id, hours, comments, activity_id, 
  spent_on, tyear, tmonth, tweek, created_on, updated_on
)
VALUES
(
  (SELECT id FROM projects WHERE identifier = 'mcp-dev'),
  (SELECT id FROM users WHERE login = 'developer'),
  (SELECT id FROM issues WHERE subject = 'Add Authentication Support to Protocol'),
  4.5,
  'Working on authentication module implementation',
  (SELECT id FROM enumerations WHERE name = 'Development' AND type = 'TimeEntryActivity'),
  CURRENT_DATE - INTERVAL '1 day',
  EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 day'),
  EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 day'),
  EXTRACT(WEEK FROM CURRENT_DATE - INTERVAL '1 day'),
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day'
),
(
  (SELECT id FROM projects WHERE identifier = 'docs'),
  (SELECT id FROM users WHERE login = 'manager'),
  (SELECT id FROM issues WHERE subject = 'Need Help with API Documentation'),
  2.0,
  'Created outline for API documentation',
  (SELECT id FROM enumerations WHERE name = 'Documentation' AND type = 'TimeEntryActivity'),
  CURRENT_DATE - INTERVAL '2 days',
  EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 days'),
  EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '2 days'),
  EXTRACT(WEEK FROM CURRENT_DATE - INTERVAL '2 days'),
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days'
);

-- Add a journal entry (issue update)
INSERT INTO journals (
  journalized_id, journalized_type, user_id, notes, created_on
)
VALUES
(
  (SELECT id FROM issues WHERE subject = 'Add Authentication Support to Protocol'),
  'Issue',
  (SELECT id FROM users WHERE login = 'developer'),
  'Started implementing the authentication module. Will use token-based authentication with JWT.',
  NOW() - INTERVAL '1 day'
);

-- Add a journal detail entry (field change)
INSERT INTO journal_details (
  journal_id, property, prop_key, old_value, value
)
VALUES
(
  (SELECT MAX(id) FROM journals),
  'attr',
  'status_id',
  (SELECT id::text FROM issue_statuses WHERE name = 'New'),
  (SELECT id::text FROM issue_statuses WHERE name = 'In Progress')
);

-- Create a saved query
INSERT INTO queries (
  name, filters, user_id, visibility, column_names, sort_criteria, 
  type, project_id, is_public
)
VALUES
(
  'High Priority Issues',
  '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
priority_id:
  :operator: "="
  :values:
    - "4"
    - "5"',
  (SELECT id FROM users WHERE login = 'admin'),
  2,  -- Public visibility
  '---
- tracker
- status
- priority
- subject
- assigned_to
- updated_on',
  '---
- - priority
  - desc
- - updated_on
  - desc',
  'IssueQuery',
  NULL,  -- Global query
  TRUE
);
