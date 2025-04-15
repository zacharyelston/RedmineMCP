-- V11__Additional_Users.sql
-- Additional user accounts for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create user A for each role type
-- Developer A
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'devA') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('devA', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Developer', 'A', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create developer A email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'devA@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'devA'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'devA')
);

-- Create API key for developer A
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'devA_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'devA'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'devA') AND action = 'api'
);

-- Manager A
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'managerA') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('managerA', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Manager', 'A', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create manager A email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'managerA@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'managerA'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'managerA')
);

-- Create API key for manager A
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'managerA_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'managerA'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'managerA') AND action = 'api'
);

-- Reporter A
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'reporterA') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('reporterA', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Reporter', 'A', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create reporter A email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'reporterA@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'reporterA'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'reporterA')
);

-- Create API key for reporter A
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'reporterA_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'reporterA'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'reporterA') AND action = 'api'
);

-- Create user B for each role type
-- Developer B
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'devB') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('devB', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Developer', 'B', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create developer B email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'devB@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'devB'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'devB')
);

-- Create API key for developer B
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'devB_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'devB'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'devB') AND action = 'api'
);

-- Manager B
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'managerB') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('managerB', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Manager', 'B', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create manager B email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'managerB@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'managerB'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'managerB')
);

-- Create API key for manager B
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'managerB_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'managerB'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'managerB') AND action = 'api'
);

-- Reporter B
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'reporterB') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('reporterB', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Reporter', 'B', FALSE, 1, 'en', NOW(), NOW(), 'User');
  END IF;
END $$;

-- Create reporter B email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
SELECT u.id, 'reporterB@example.com', TRUE, TRUE, NOW(), NOW() 
FROM users u WHERE u.login = 'reporterB'
AND NOT EXISTS (
  SELECT 1 FROM email_addresses 
  WHERE user_id = (SELECT id FROM users WHERE login = 'reporterB')
);

-- Create API key for reporter B
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
SELECT u.id, 'api', 'reporterB_api_key', NOW(), NOW()
FROM users u WHERE u.login = 'reporterB'
AND NOT EXISTS (
  SELECT 1 FROM tokens 
  WHERE user_id = (SELECT id FROM users WHERE login = 'reporterB') AND action = 'api'
);

-- Assign users to appropriate roles
DO $$
DECLARE
  v_project_id INTEGER;
  v_member_id INTEGER;
  v_dev_role_id INTEGER;
  v_manager_role_id INTEGER;
  v_reporter_role_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  
  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';

  -- Developer A
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'devA') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'devA'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_dev_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_dev_role_id);
      END IF;
    END IF;
  END IF;

  -- Developer B
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'devB') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'devB'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_dev_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_dev_role_id);
      END IF;
    END IF;
  END IF;

  -- Manager A
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'managerA') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'managerA'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_manager_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_manager_role_id);
      END IF;
    END IF;
  END IF;

  -- Manager B
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'managerB') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'managerB'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_manager_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_manager_role_id);
      END IF;
    END IF;
  END IF;

  -- Reporter A
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'reporterA') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'reporterA'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_reporter_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_reporter_role_id);
      END IF;
    END IF;
  END IF;

  -- Reporter B
  IF v_project_id IS NOT NULL THEN
    -- Check if member exists
    SELECT id INTO v_member_id FROM members 
    WHERE user_id = (SELECT id FROM users WHERE login = 'reporterB') AND project_id = v_project_id;
    
    -- Create member if not exists
    IF v_member_id IS NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES ((SELECT id FROM users WHERE login = 'reporterB'), v_project_id, NOW())
      RETURNING id INTO v_member_id;
      
      -- Add role
      IF v_reporter_role_id IS NOT NULL THEN
        INSERT INTO member_roles (member_id, role_id)
        VALUES (v_member_id, v_reporter_role_id);
      END IF;
    END IF;
  END IF;
END $$;
