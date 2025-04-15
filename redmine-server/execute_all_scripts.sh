#!/bin/bash
# execute_all_scripts.sh
# Execute all SQL scripts in order to create and configure trackers
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Setting up MCP trackers in Redmine database..."

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

# Execute each SQL script in order
echo "Step 1: Creating issue priorities..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/create_priorities.sql

echo "Step 2: Creating trackers..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/01_create_tracker.sql

echo "Step 3: Associating trackers with project..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/02_associate_with_project.sql

echo "Step 4: Setting up Developer workflows..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/03_create_workflow_developer.sql

echo "Step 5: Setting up Manager workflows..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/04_create_workflow_manager.sql

echo "Step 6: Setting up Reporter workflows..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/05_create_workflow_reporter.sql

echo "Step 7: Verifying tracker configuration..."
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/06_verify_trackers.sql

echo "Restarting Redmine container to apply changes..."
docker restart redmine-app

echo "Done! Wait a few seconds for Redmine to restart."
echo "You can now create issues using the MCP trackers:"
echo "redmine_issues_create({"
echo "  project_id: 1,"
echo "  subject: \"Your issue subject\","
echo "  tracker_id: 4,  # For MCP Test Case, or 5 for MCP Documentation"
echo "  priority_id: 2, # Normal priority"
echo "  description: \"Your issue description\""
echo "});"
