-- V10__User_Project_Roles_Fixed.sql
-- User role assignments for the MCP project
-- Part of the ModelContextProtocol (MCP) Implementation
-- This should be run AFTER creating both users and the project

-- Assign users to roles using PL/pgSQL to avoid having to deal with NULL values
DO $$
DECLARE
  v_project_id INTEGER;
  v_dev_user_id INTEGER;
  v_manager_user_id INTEGER;
  v_test_user_id INTEGER;
  v_dev_role_id INTEGER;
  v_manager_role_id INTEGER;
  v_reporter_role_id INTEGER;
  v_member_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';

  -- Get user IDs
  SELECT id INTO v_dev_user_id FROM users WHERE login = 'developer';
  SELECT id INTO v_manager_user_id FROM users WHERE login = 'manager';
  SELECT id INTO v_test_user_id FROM users WHERE login = 'testuser';

  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';

  -- Developer role
  IF v_project_id IS NOT NULL AND v_dev_user_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = v_dev_user_id AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_dev_user_id, v_project_id, NOW())
      RETURNING id INTO v_member_id;
    END IF;
    
    -- Add role if not already assigned
    IF NOT EXISTS (SELECT 1 FROM member_roles 
                  WHERE member_id = v_member_id AND role_id = v_dev_role_id) THEN
      INSERT INTO member_roles (member_id, role_id)
      VALUES (v_member_id, v_dev_role_id);
    END IF;
  END IF;

  -- Manager role
  IF v_project_id IS NOT NULL AND v_manager_user_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = v_manager_user_id AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_manager_user_id, v_project_id, NOW())
      RETURNING id INTO v_member_id;
    END IF;
    
    -- Add role if not already assigned
    IF NOT EXISTS (SELECT 1 FROM member_roles 
                  WHERE member_id = v_member_id AND role_id = v_manager_role_id) THEN
      INSERT INTO member_roles (member_id, role_id)
      VALUES (v_member_id, v_manager_role_id);
    END IF;
  END IF;

  -- Test user role
  IF v_project_id IS NOT NULL AND v_test_user_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = v_test_user_id AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_test_user_id, v_project_id, NOW())
      RETURNING id INTO v_member_id;
    END IF;
    
    -- Add role if not already assigned
    IF NOT EXISTS (SELECT 1 FROM member_roles 
                  WHERE member_id = v_member_id AND role_id = v_reporter_role_id) THEN
      INSERT INTO member_roles (member_id, role_id)
      VALUES (v_member_id, v_reporter_role_id);
    END IF;
  END IF;
END $$;
