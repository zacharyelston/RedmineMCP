#!/bin/bash
# Script to set the API key for the admin user in Redmine
# ModelContextProtocol (MCP) Implementation

API_TOKEN="7a4ed5c91b405d30fda60909dbc86c2651c38217"
echo "Setting API token for admin user: $API_TOKEN"

# First, check if the tokens table exists
echo "Checking if tokens table exists..."
if psql -U redmine -d redmine -c "\d tokens" > /dev/null 2>&1; then
    echo "Tokens table found, setting API token..."
    
    # Check if there's already an API token for admin
    TOKEN_EXISTS=$(psql -U redmine -d redmine -t -c "SELECT COUNT(*) FROM tokens WHERE user_id = 1 AND action = 'api'")
    
    if [ "$TOKEN_EXISTS" -gt "0" ]; then
        # Update existing token
        psql -U redmine -d redmine -c "UPDATE tokens SET value = '$API_TOKEN', updated_on = NOW() WHERE user_id = 1 AND action = 'api'"
        echo "Updated existing API token"
    else
        # Insert new token
        psql -U redmine -d redmine -c "INSERT INTO tokens (user_id, action, value, created_on, updated_on) VALUES (1, 'api', '$API_TOKEN', NOW(), NOW())"
        echo "Inserted new API token"
    fi
    
    # Verify token was set
    TOKEN_VALUE=$(psql -U redmine -d redmine -t -c "SELECT value FROM tokens WHERE user_id = 1 AND action = 'api'")
    echo "API token value in database: $TOKEN_VALUE"
    
    echo "API token setup complete"
else
    # In older versions of Redmine, the API key is stored directly in the users table
    echo "Tokens table not found, checking for api_key column in users table..."
    
    if psql -U redmine -d redmine -c "\d users" | grep -q "api_key"; then
        echo "api_key column found in users table, setting API key..."
        psql -U redmine -d redmine -c "UPDATE users SET api_key = '$API_TOKEN' WHERE id = 1"
        echo "API key set in users table"
    else
        echo "No suitable API key storage found in database."
        echo "API key will need to be generated via the Redmine UI."
        echo "Go to My Account -> API access key -> Show/Generate"
    fi
fi

echo "Script completed."
