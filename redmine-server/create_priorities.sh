#!/bin/bash
# create_priorities.sh
# Script to create issue priorities in Redmine
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Creating issue priorities in Redmine database..."

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "Loaded environment from .env file"
else
    echo "Warning: .env file not found, using default values"
    POSTGRES_USER=postgres
    POSTGRES_PASSWORD=postgres
    POSTGRES_DB=redmine
fi

# Hardcode the container name based on the docker ps output
POSTGRES_CONTAINER="redmine-postgres"

echo "Using PostgreSQL container: ${POSTGRES_CONTAINER}"

# Execute the SQL script inside the PostgreSQL container
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/create_priorities.sql

echo "Priorities created successfully!"
echo "Restarting Redmine container to apply changes..."

# Restart the Redmine container
docker restart redmine-app

echo "Done! Wait a few seconds for Redmine to restart."
echo "Now try creating an issue with:"
echo "redmine_issues_create({"
echo "  project_id: 1,"
echo "  subject: \"Test Issue for Troubleshooting\","
echo "  tracker_id: 1,"
echo "  priority_id: 2,"
echo "  description: \"This is a test issue for troubleshooting purposes.\""
echo "});"
