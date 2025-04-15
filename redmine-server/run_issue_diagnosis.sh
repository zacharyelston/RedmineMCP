#!/bin/bash
# run_issue_diagnosis.sh
# Script to run the issue creation diagnosis SQL
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Running issue creation diagnosis..."

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
echo "Database diagnosis results:"
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/diagnose_issue_creation.sql

echo "Done! Now let's try to create a test issue with minimal parameters."
echo "Try using this function in your code:"
echo "redmine_issues_create({"
echo "  project_id: 1,"
echo "  subject: \"Test Issue for Troubleshooting\","
echo "  tracker_id: 1,"
echo "  priority_id: 2,"
echo "  description: \"This is a test issue for troubleshooting purposes.\""
echo "});"
