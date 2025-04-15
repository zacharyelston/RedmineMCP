#!/bin/bash
# check_tokens.sh
# Script to check API tokens in Redmine
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Checking Redmine API tokens..."

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "Loaded environment from .env file"
    echo "ADMIN_API_KEY = $ADMIN_API_KEY"
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
docker exec -i ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < ./sql/check_tokens.sql

echo "Tokens check complete."
