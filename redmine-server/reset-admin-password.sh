#!/bin/bash
# Script to reset the admin password in Redmine
# This directly updates the database with a new hashed password

echo "Resetting admin password to 'admin'..."

# Execute SQL to update the admin user password
# This sets it to the known default 'admin' password
docker exec -it redmine-postgres psql -U redmine -d redmine -c "UPDATE users SET hashed_password = '353e8061f2befecb6818ba0c034c632fb0bcae1b', salt = '3126f764c3c5ac61cbfc103178ebb78365e6c949' WHERE login = 'admin';"

echo "Password reset complete. You should now be able to login with:"
echo "Username: admin"
echo "Password: admin"
echo
echo "After logging in, you can change the password in the UI if needed."
