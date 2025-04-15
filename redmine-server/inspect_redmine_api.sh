#!/bin/bash
# inspect_redmine_api.sh
# Script to inspect Redmine API configuration
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Inspecting Redmine API configuration..."

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
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/inspect_redmine_api.sql

echo "API inspection complete."
echo ""
echo "To test a minimal issue creation request directly to the Redmine API:"
echo "curl -v -X POST -H \"Content-Type: application/json\" -H \"X-Redmine-API-Key: $ADMIN_API_KEY\" \\"
echo "  http://localhost:3000/issues.json \\"
echo "  -d '{\"issue\": {\"project_id\": 1, \"subject\": \"Test Issue\", \"tracker_id\": 1, \"priority_id\": 2, \"status_id\": 1}}'"
