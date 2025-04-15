#!/bin/bash
# Script to set admin password and API token for Redmine
# ModelContextProtocol (MCP) Implementation

# Wait for Redmine to initialize
echo "Waiting for Redmine database to be ready..."
sleep 10

# Set the admin password
echo "Setting admin password to 'RedmineMCP!'..."
psql -U redmine -d redmine -c "UPDATE users SET hashed_password = '7c1f01dc7b386fc2fe888d8f00f505325cce6a8e', salt = '51843e128ecbf9d1c15d7222b327e42e2a86dbed' WHERE login = 'admin';"

# Set the API token if the tokens table exists (depends on Redmine version)
echo "Attempting to set API token..."
if psql -U redmine -d redmine -c "\d tokens" > /dev/null 2>&1; then
  psql -U redmine -d redmine -c "INSERT INTO tokens (user_id, action, value, created_on, updated_on) VALUES (1, 'api', '7a4ed5c91b405d30fda60909dbc86c2651c38217', NOW(), NOW()) ON CONFLICT (user_id, action) DO UPDATE SET value = '7a4ed5c91b405d30fda60909dbc86c2651c38217', updated_on = NOW();"
  echo "API token set successfully"
else
  echo "API token table not found - token will need to be generated via web UI"
fi

echo "Configuration complete"
