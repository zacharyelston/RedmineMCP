#!/bin/bash
# Set predefined API token for Redmine

# Wait for Redmine to fully initialize
sleep 30

# Set the predefined API token in the database
psql -h postgres -U redmine -d redmine -c "UPDATE users SET api_key='7a4ed5c91b405d30fda60909dbc86c2651c38217' WHERE login='admin';"

echo "API token for admin user has been set to 7a4ed5c91b405d30fda60909dbc86c2651c38217"
