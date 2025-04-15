#!/bin/bash
# direct_create_issue.sh
# Script to create issues directly via the Redmine API
# Part of the ModelContextProtocol (MCP) Implementation

set -e  # Exit immediately if a command exits with a non-zero status

echo "Creating issue directly via Redmine API..."

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

# Collect input parameters
project_id=${1:-1}  # Default to project 1 if not specified
subject=${2:-"Test Issue from direct script"}
tracker_id=${3:-1}  # Default to Bug tracker if not specified
priority_id=${4:-2}  # Default to Normal priority if not specified

# Create the issue
echo "Creating issue with:"
echo "  Project ID: $project_id"
echo "  Subject: $subject"
echo "  Tracker ID: $tracker_id"
echo "  Priority ID: $priority_id"

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $ADMIN_API_KEY" \
  http://localhost:3000/issues.json \
  -d "{\"issue\": {\"project_id\": $project_id, \"subject\": \"$subject\", \"tracker_id\": $tracker_id, \"priority_id\": $priority_id, \"status_id\": 1}}" \
  | jq '.'

echo ""
echo "Issue created successfully."
echo ""
echo "To create an issue with the MCP function, use:"
echo "redmine_issues_create({"
echo "  \"project_id\": $project_id,"
echo "  \"subject\": \"$subject\","
echo "  \"tracker_id\": $tracker_id,"
echo "  \"priority_id\": $priority_id,"
echo "  \"status_id\": 1"
echo "});"
