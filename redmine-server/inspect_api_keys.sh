#!/bin/bash
# inspect_api_keys.sh
# Script to inspect Redmine API keys configuration
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Inspecting Redmine API keys configuration..."

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
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/inspect_api_keys.sql

echo "API keys inspection complete."
