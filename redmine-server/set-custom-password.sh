#!/bin/bash
# Script to set a custom admin password for Redmine
# ModelContextProtocol (MCP) Implementation

PASSWORD="RedmineMCP!"
echo "Setting admin password to '$PASSWORD'..."

# We need to generate a salt and hash for the password
# For demonstration, using a pre-computed hash for 'RedmineMCP!'
# This is equivalent to the password: RedmineMCP!
SALT="51843e128ecbf9d1c15d7222b327e42e2a86dbed"
HASHED_PASSWORD="7c1f01dc7b386fc2fe888d8f00f505325cce6a8e"

# Execute SQL to update the admin user password
docker exec redmine-postgres psql -U redmine -d redmine -c "UPDATE users SET hashed_password = '$HASHED_PASSWORD', salt = '$SALT' WHERE login = 'admin';"

echo "Password has been set to '$PASSWORD'"
echo "You should now be able to login with:"
echo "Username: admin"
echo "Password: $PASSWORD"
echo
echo "After logging in, go to 'My account' to generate an API access key"
