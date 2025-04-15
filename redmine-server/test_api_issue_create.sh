#!/bin/bash
# test_api_issue_create.sh
# Script to test issue creation via direct API call
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Testing issue creation via direct API call..."

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "Loaded environment from .env file"
    echo "Using ADMIN_API_KEY: $ADMIN_API_KEY"
else
    echo "Warning: .env file not found, using default values"
    ADMIN_API_KEY="7a4ed5c91b405d30fda60909dbc86c2651c38217"
    echo "Using hardcoded API key: $ADMIN_API_KEY"
fi

echo "Testing with standard parameters..."
curl -v -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $ADMIN_API_KEY" \
  http://localhost:3000/issues.json \
  -d '{"issue": {"project_id": 1, "subject": "Test Issue", "tracker_id": 1, "priority_id": 2, "status_id": 1}}'

echo ""
echo "Testing with additional parameters..."
curl -v -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $ADMIN_API_KEY" \
  http://localhost:3000/issues.json \
  -d '{"issue": {"project_id": 1, "subject": "Test Issue with Author", "tracker_id": 1, "priority_id": 2, "status_id": 1, "author_id": 1}}'

echo ""
echo "Done."
