-- V15__Create_Groups.sql
-- Create user groups for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create Developers group
DO $$
DECLARE
  v_group_id INTEGER;
  v_user_id INTEGER;
  v_dev_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Check if Developers group exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Developers') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Developers', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Add developer user to the group if exists
    SELECT id INTO v_user_id FROM users WHERE login = 'developer' AND type = 'User';
    IF v_user_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      INSERT INTO groups_users (group_id, user_id)
      VALUES (v_group_id, v_user_id);
    END IF;
    
    -- Get Developer role ID
    SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
    
    -- Get project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
    
    -- Assign group to project with Developer role
    IF v_dev_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_dev_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;

-- Create Managers group
DO $$
DECLARE
  v_group_id INTEGER;
  v_user_id INTEGER;
  v_manager_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Check if Managers group exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Managers') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Managers', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Add manager user to the group if exists
    SELECT id INTO v_user_id FROM users WHERE login = 'manager' AND type = 'User';
    IF v_user_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      INSERT INTO groups_users (group_id, user_id)
      VALUES (v_group_id, v_user_id);
    END IF;
    
    -- Get Manager role ID
    SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
    
    -- Get project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
    
    -- Assign group to project with Manager role
    IF v_manager_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_manager_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;

-- Create QA Team group
DO $$
DECLARE
  v_group_id INTEGER;
  v_reporter_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Check if QA Team group exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'QA Team') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'QA Team', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Get Reporter role ID
    SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';
    
    -- Get project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
    
    -- Assign group to project with Reporter role
    IF v_reporter_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_reporter_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;

-- Create Support Team group
DO $$
DECLARE
  v_group_id INTEGER;
  v_reporter_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Check if Support Team group exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Support Team') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Support Team', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Get Reporter role ID (or create specific Support role if needed)
    SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';
    
    -- Get project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
    
    -- Assign group to project with Reporter role
    IF v_reporter_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_reporter_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;

-- Create Project Owners group
DO $$
DECLARE
  v_group_id INTEGER;
  v_manager_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Check if Project Owners group exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Project Owners') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Project Owners', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Add admin to the group
    INSERT INTO groups_users (group_id, user_id)
    SELECT v_group_id, id
    FROM users
    WHERE login = 'admin' AND type = 'User'
    ON CONFLICT DO NOTHING;
    
    -- Get Manager role ID
    SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
    
    -- Get project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
    
    -- Assign group to project with Manager role
    IF v_manager_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_manager_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;