-- inspect_api_keys.sql
-- Script to inspect Redmine API keys configuration
-- Part of the ModelContextProtocol (MCP) Implementation

-- Check users table structure
\d users

-- List all tables that might contain API keys
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%api%' OR table_name LIKE '%token%';

-- Check if the tokens table exists and its structure
\d tokens

-- Check settings related to API again
SELECT * FROM settings WHERE name LIKE '%api%' OR name LIKE '%token%';

-- Check if REST API is enabled and in what mode
SELECT * FROM settings WHERE name = 'rest_api_enabled';

-- Check for any hint in the schema about where API keys are stored
SELECT t.table_name, c.column_name
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE c.table_schema = 'public'
AND (
  c.column_name LIKE '%api%' OR 
  c.column_name LIKE '%token%' OR 
  c.column_name LIKE '%key%'
);
