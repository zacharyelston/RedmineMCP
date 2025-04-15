-- create_workflow_manager_role.sql
-- Creates a special role for workflow management
-- This user can manage workflows but doesn't have full admin privileges
-- Created for MCP Issue #103 - Workflow Management

-- First, check if the WorkflowManager role already exists
SET @role_exists = (SELECT COUNT(*) FROM roles WHERE name = 'WorkflowManager');

-- Create the role if it doesn't exist
INSERT INTO roles (name, position, assignable, builtin, permissions)
SELECT 
  'WorkflowManager', 
  (SELECT MAX(position) + 1 FROM roles), 
  1, -- Assignable
  0, -- Not built-in
  '---
- :manage_project
- :manage_versions
- :manage_categories
- :manage_issue_templates
- :create_project
- :add_project
- :edit_project
- :select_project_modules
- :manage_members
- :manage_roles
- :manage_issue_statuses
- :manage_workflow
- :view_issues
- :add_issues
- :edit_issues
- :manage_issue_relations
- :manage_subtasks
- :set_issues_private
- :set_own_issues_private
- :add_issue_notes
- :edit_issue_notes
- :edit_own_issue_notes
- :view_private_notes
- :view_wiki_edits
- :edit_wiki_pages'
WHERE @role_exists = 0;

SELECT IF(@role_exists = 0, 'WorkflowManager role created', 'WorkflowManager role already exists') AS 'Result';

-- Create a user with this role if not exists
SET @user_exists = (SELECT COUNT(*) FROM users WHERE login = 'workflow_manager');

INSERT INTO users (
  login, 
  hashed_password, 
  firstname, 
  lastname, 
  admin, 
  status, 
  last_login_on, 
  language, 
  auth_source_id, 
  created_on, 
  updated_on, 
  type, 
  identity_url, 
  mail_notification, 
  salt, 
  must_change_passwd, 
  passwd_changed_on
)
SELECT 
  'workflow_manager', 
  -- The hash below is for password 'workflow123' - you should change this in production
  '1c8bbaf472d1cec73c21def2a6e669944156aae4', 
  'Workflow', 
  'Manager', 
  0, -- Not admin
  1, -- Active
  NULL, 
  'en', 
  NULL, 
  NOW(), 
  NOW(), 
  'User', 
  NULL, 
  '', 
  'workflow_salt_123', -- Change this salt in production
  0, 
  NOW()
WHERE @user_exists = 0;

SELECT IF(@user_exists = 0, 'Workflow Manager user created', 'Workflow Manager user already exists') AS 'Result';

-- Now, let's create a token for the workflow manager API access
SET @user_id = (SELECT id FROM users WHERE login = 'workflow_manager');
SET @token_exists = (SELECT COUNT(*) FROM tokens WHERE user_id = @user_id AND action = 'api');

INSERT INTO tokens (
  user_id,
  action,
  value,
  created_on,
  updated_on
)
SELECT
  @user_id,
  'api',
  -- This is a generated token - replace in production
  '5a7b4e3c1d9f8g6h2i5j7k2l1m3n4o5p',
  NOW(),
  NOW()
WHERE @token_exists = 0;

SELECT IF(@token_exists = 0, 'API Token created for workflow manager', 'API Token already exists for workflow manager') AS 'Result';

-- Finally create global membership to give workflow manager access to all projects
INSERT INTO members (user_id, project_id, created_on, mail_notification)
SELECT 
  @user_id, 
  p.id, 
  NOW(), 
  FALSE
FROM 
  projects p
WHERE NOT EXISTS (
  SELECT 1 FROM members WHERE user_id = @user_id AND project_id = p.id
);

-- Add role to memberships
INSERT INTO member_roles (member_id, role_id)
SELECT 
  m.id, 
  (SELECT id FROM roles WHERE name = 'WorkflowManager')
FROM 
  members m
WHERE 
  m.user_id = @user_id
AND NOT EXISTS (
  SELECT 1 FROM member_roles 
  WHERE member_id = m.id 
  AND role_id = (SELECT id FROM roles WHERE name = 'WorkflowManager')
);

-- Output the API key for this user
SELECT 
  u.login AS username,
  t.value AS api_key,
  'Add this API key to your .env file or use it in API requests' AS note
FROM 
  users u
JOIN 
  tokens t ON u.id = t.user_id
WHERE 
  u.login = 'workflow_manager'
AND
  t.action = 'api';

-- Check role memberships
SELECT 
  u.login AS username, 
  r.name AS role,
  COUNT(DISTINCT p.id) AS project_count
FROM 
  users u
JOIN 
  members m ON u.id = m.user_id
JOIN 
  member_roles mr ON m.id = mr.member_id
JOIN 
  roles r ON mr.role_id = r.id
JOIN 
  projects p ON m.project_id = p.id
WHERE 
  u.login = 'workflow_manager'
GROUP BY 
  u.login, r.name;
