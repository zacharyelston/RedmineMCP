-- check_tokens.sql
-- Script to check the API tokens in Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- Check tokens table for API keys
SELECT t.id, t.user_id, t.action, t.value, t.created_on, u.login, u.admin
FROM tokens t
JOIN users u ON t.user_id = u.id
WHERE t.action = 'api';

-- Check if our API key exists
SELECT t.id, t.user_id, t.action, t.value, t.created_on, u.login, u.admin
FROM tokens t
JOIN users u ON t.user_id = u.id
WHERE t.value = '7a4ed5c91b405d30fda60909dbc86c2651c38217';

-- Check the admin user to see the user_id
SELECT id, login, admin, firstname, lastname
FROM users
WHERE admin = TRUE;
