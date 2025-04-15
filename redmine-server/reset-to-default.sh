#!/bin/bash
# Reset Redmine admin to default password
# ModelContextProtocol (MCP) Implementation

echo "Resetting admin password to default 'admin'..."

# These are the known default hash and salt for 'admin' password
SALT="3126f764c3c5ac61cbfc103178ebb78365e6c949"
HASH="353e8061f2befecb6818ba0c034c632fb0bcae1b"

# Execute SQL to update the admin user password
docker exec redmine-postgres psql -U redmine -d redmine -c "UPDATE users SET hashed_password = '$HASH', salt = '$SALT' WHERE login = 'admin';"

echo "Password has been reset to 'admin'"
echo "You should now be able to login with:"
echo "Username: admin"
echo "Password: admin"
