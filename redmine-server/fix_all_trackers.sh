#!/bin/bash
# fix_all_trackers.sh
# Script to fix all trackers missing default_status_id
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Fixing all trackers with missing default_status_id..."

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
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/fix_all_trackers.sql

echo "All trackers fixed successfully!"
echo "Restarting Redmine container to apply changes..."

# Restart the Redmine container
docker restart redmine-app

echo "Done. Wait a few seconds for Redmine to restart, then try accessing http://localhost:3000/trackers again."
