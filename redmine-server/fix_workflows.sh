#!/bin/bash
# fix_workflows.sh
# Script to fix missing workflow configurations
# Created for MCP Issue #103 - Workflow Configuration Fix

set -e  # Exit immediately if a command exits with a non-zero status

echo "=== Redmine Workflow Fix Script ==="
echo "Fixing missing workflow configurations..."

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

# Determine the PostgreSQL container name
POSTGRES_CONTAINER=$(docker ps -qf "name=postgres")
if [ -z "$POSTGRES_CONTAINER" ]; then
    POSTGRES_CONTAINER="redmine-postgres"  # Fallback container name
    echo "No postgres container found by docker ps, using fallback name: ${POSTGRES_CONTAINER}"
else
    echo "Found PostgreSQL container: ${POSTGRES_CONTAINER}"
fi

# Execute the workflow fix SQL script
echo -e "\n=== Fixing workflow configurations ==="
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/fix_workflows_complete.sql

echo -e "\n=== Workflow fixes completed ==="
echo "You should now be able to update issue #93 status to 'Closed'"

# Determine the Redmine container name
REDMINE_CONTAINER=$(docker ps -qf "name=redmine")
if [ -z "$REDMINE_CONTAINER" ]; then
    REDMINE_CONTAINER="redmine-app"  # Fallback container name
    echo "No redmine container found by docker ps, using fallback name: ${REDMINE_CONTAINER}"
else
    echo "Found Redmine container: ${REDMINE_CONTAINER}"
fi

echo -e "\nTo close issue #93 using the API, run:"
echo "curl -X PUT -H \"Content-Type: application/json\" -H \"X-Redmine-API-Key: 7a4ed5c91b405d30fda60909dbc86c2651c38217\" -d '{\"issue\":{\"status_id\":5,\"notes\":\"Closing after workflow fix\"}}' http://localhost:3000/issues/93.json"

echo -e "\n=== Restarting Redmine to apply changes ==="
docker restart ${REDMINE_CONTAINER}

echo "Done. Wait a few seconds for Redmine to restart, then try accessing http://localhost:3000/issues/93 again."
