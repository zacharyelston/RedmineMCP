-- inspect_redmine_api.sql
-- Script to inspect Redmine API configuration
-- Part of the ModelContextProtocol (MCP) Implementation

-- Check if REST API is enabled
SELECT * FROM settings WHERE name = 'rest_api_enabled';

-- Check if API key auth is enabled
SELECT * FROM settings WHERE name LIKE '%api%';

-- Check API access settings
SELECT * FROM settings WHERE name LIKE '%access%';

-- Check user API keys
SELECT id, login, firstname, lastname, admin, status, api_key
FROM users
WHERE api_key IS NOT NULL;

-- Check if the API key being used matches any in the database
SELECT COUNT(*) as key_match_count
FROM users
WHERE api_key = '7a4ed5c91b405d30fda60909dbc86c2651c38217'; -- This should match the ADMIN_API_KEY from .env

-- Check project permissions for issue tracking
SELECT p.id, p.name, p.identifier, em.name as module
FROM projects p
JOIN enabled_modules em ON p.id = em.project_id
WHERE p.identifier = 'mcp-project' AND em.name = 'issue_tracking';

-- Check if there are any issues at all in the database (even those that might be hidden)
SELECT * FROM issues LIMIT 5;
