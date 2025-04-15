-- V7__User_Accounts_Fixed2.sql
-- User accounts migration for Redmine
-- Part of the ModelContextProtocol (MCP) Implementation
-- Fixed version to avoid ON CONFLICT issues

-- Admin user - already created, but we'll update its API key
UPDATE users SET admin = TRUE WHERE login = 'admin';

-- Check if admin API token exists, if not create it
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tokens WHERE user_id = 1 AND action = 'api') THEN
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (1, 'api', '7a4ed5c91b405d30fda60909dbc86c2651c38217', NOW(), NOW());
  ELSE
    UPDATE tokens SET value = '7a4ed5c91b405d30fda60909dbc86c2651c38217', updated_on = NOW()
    WHERE user_id = 1 AND action = 'api';
  END IF;
END $$;

-- Create test user (if not exists)
DO $$
DECLARE
  v_user_id INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'testuser') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('testuser', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Test', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'test@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', '3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0', NOW(), NOW());
  ELSE
    -- User exists, make sure email and API key exist
    SELECT id INTO v_user_id FROM users WHERE login = 'testuser';
    
    -- Add email if not exists
    IF NOT EXISTS (SELECT 1 FROM email_addresses WHERE user_id = v_user_id) THEN
      INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
      VALUES (v_user_id, 'test@example.com', TRUE, TRUE, NOW(), NOW());
    END IF;
    
    -- Add API key if not exists
    IF NOT EXISTS (SELECT 1 FROM tokens WHERE user_id = v_user_id AND action = 'api') THEN
      INSERT INTO tokens (user_id, action, value, created_on, updated_on)
      VALUES (v_user_id, 'api', '3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0', NOW(), NOW());
    END IF;
  END IF;
END $$;

-- Create developer user (if not exists)
DO $$
DECLARE
  v_user_id INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'developer') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('developer', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Dev', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'dev@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', 'f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f', NOW(), NOW());
  ELSE
    -- User exists, make sure email and API key exist
    SELECT id INTO v_user_id FROM users WHERE login = 'developer';
    
    -- Add email if not exists
    IF NOT EXISTS (SELECT 1 FROM email_addresses WHERE user_id = v_user_id) THEN
      INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
      VALUES (v_user_id, 'dev@example.com', TRUE, TRUE, NOW(), NOW());
    END IF;
    
    -- Add API key if not exists
    IF NOT EXISTS (SELECT 1 FROM tokens WHERE user_id = v_user_id AND action = 'api') THEN
      INSERT INTO tokens (user_id, action, value, created_on, updated_on)
      VALUES (v_user_id, 'api', 'f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f', NOW(), NOW());
    END IF;
  END IF;
END $$;

-- Create manager user (if not exists)
DO $$
DECLARE
  v_user_id INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'manager') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('manager', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Project', 'Manager', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'manager@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', '5c98f85a9f2e34c3b217758e910e196c7a77bf5b', NOW(), NOW());
  ELSE
    -- User exists, make sure email and API key exist
    SELECT id INTO v_user_id FROM users WHERE login = 'manager';
    
    -- Add email if not exists
    IF NOT EXISTS (SELECT 1 FROM email_addresses WHERE user_id = v_user_id) THEN
      INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
      VALUES (v_user_id, 'manager@example.com', TRUE, TRUE, NOW(), NOW());
    END IF;
    
    -- Add API key if not exists
    IF NOT EXISTS (SELECT 1 FROM tokens WHERE user_id = v_user_id AND action = 'api') THEN
      INSERT INTO tokens (user_id, action, value, created_on, updated_on)
      VALUES (v_user_id, 'api', '5c98f85a9f2e34c3b217758e910e196c7a77bf5b', NOW(), NOW());
    END IF;
  END IF;
END $$;