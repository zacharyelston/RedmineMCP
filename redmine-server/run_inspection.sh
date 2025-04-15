#!/bin/bash
# run_inspection.sh
# Script to run the tracker inspection SQL
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Running tracker inspection..."

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
echo "Database inspection results:"
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./inspect_trackers.sql
