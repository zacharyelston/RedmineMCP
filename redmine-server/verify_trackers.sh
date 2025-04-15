#!/bin/bash
# verify_trackers.sh
# Script to verify that trackers were added to Redmine database
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Verifying trackers in Redmine database..."

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

# Query to list all trackers
echo "List of trackers in the database:"
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT id, name, description, position, is_in_roadmap FROM trackers ORDER BY position;"

# Query to check tracker associations with projects
echo -e "\nTracker-Project associations:"
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
SELECT p.identifier AS project, t.name AS tracker
FROM projects p
JOIN projects_trackers pt ON p.id = pt.project_id
JOIN trackers t ON pt.tracker_id = t.id
WHERE p.identifier = 'mcp-project'
ORDER BY t.position;"

# Query to check workflow rules for our custom trackers
echo -e "\nWorkflow rules for custom trackers:"
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
SELECT t.name AS tracker, r.name AS role, 
       old_status.name AS old_status, new_status.name AS new_status
FROM workflows w
JOIN trackers t ON w.tracker_id = t.id
JOIN roles r ON w.role_id = r.id
JOIN issue_statuses old_status ON w.old_status_id = old_status.id
JOIN issue_statuses new_status ON w.new_status_id = new_status.id
WHERE t.name IN ('MCP Documentation', 'MCP Test Case')
AND w.type IS NULL
ORDER BY t.name, r.name, old_status.name;"
