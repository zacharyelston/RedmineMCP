#!/bin/bash
# Script to ensure Redmine has the default admin credentials
# and generate the required API token

# Wait for Redmine to initialize
sleep 15

# These are the known default values for the admin user
ADMIN_SALT="3126f764c3c5ac61cbfc103178ebb78365e6c949"
ADMIN_HASH="353e8061f2befecb6818ba0c034c632fb0bcae1b"
API_TOKEN="7a4ed5c91b405d30fda60909dbc86c2651c38217"

# Reset the admin password to the default
echo "Setting admin password to 'admin'..."
psql -U redmine -d redmine -c "UPDATE users SET hashed_password = '$ADMIN_HASH', salt = '$ADMIN_SALT' WHERE login = 'admin';"

# Try to set the API token if the tokens table exists
echo "Attempting to set API token..."
if psql -U redmine -d redmine -c "\d tokens" > /dev/null 2>&1; then
  psql -U redmine -d redmine -c "INSERT INTO tokens (user_id, action, value, created_on, updated_on) 
                                VALUES (1, 'api', '$API_TOKEN', NOW(), NOW()) 
                                ON CONFLICT (user_id, action) DO UPDATE SET value = '$API_TOKEN', updated_on = NOW();"
  echo "API token set successfully"
else
  echo "Tokens table not found - API token will need to be generated via the UI"
fi

echo "Admin setup complete"
