#!/bin/bash

# This script tests the Redmine API to ensure it's working correctly
# It requires a valid credentials.yaml file with correct Redmine API key

# Function to read the credentials file
read_credentials() {
  if [ -f "credentials.yaml" ]; then
    echo "Reading credentials from credentials.yaml..."
    REDMINE_URL=$(grep "redmine_url:" credentials.yaml | awk '{print $2}' | tr -d '"')
    REDMINE_API_KEY=$(grep "redmine_api_key:" credentials.yaml | awk '{print $2}' | tr -d '"')
    
    # Validate the values
    if [ -z "$REDMINE_URL" ] || [ -z "$REDMINE_API_KEY" ]; then
      echo "Error: Missing Redmine URL or API key in credentials.yaml"
      exit 1
    fi
  else
    echo "Error: credentials.yaml file not found. Run setup_redmine.sh first."
    exit 1
  fi
}

# Function to test projects endpoint
test_projects() {
  echo "Testing projects endpoint..."
  curl -s -X GET "$REDMINE_URL/projects.json" \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    | jq .
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve projects. Check your Redmine URL and API key."
    exit 1
  fi
}

# Function to test issues endpoint
test_issues() {
  echo "Testing issues endpoint..."
  curl -s -X GET "$REDMINE_URL/issues.json" \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    | jq .
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve issues. Check your Redmine URL and API key."
    exit 1
  fi
}

# Function to test trackers endpoint
test_trackers() {
  echo "Testing trackers endpoint..."
  curl -s -X GET "$REDMINE_URL/trackers.json" \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    | jq .
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve trackers. Check your Redmine URL and API key."
    exit 1
  fi
}

# Function to test issue statuses endpoint
test_issue_statuses() {
  echo "Testing issue statuses endpoint..."
  curl -s -X GET "$REDMINE_URL/issue_statuses.json" \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    | jq .
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve issue statuses. Check your Redmine URL and API key."
    exit 1
  fi
}

# Function to test issue priorities endpoint
test_issue_priorities() {
  echo "Testing issue priorities endpoint..."
  curl -s -X GET "$REDMINE_URL/enumerations/issue_priorities.json" \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    | jq .
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve issue priorities. Check your Redmine URL and API key."
    exit 1
  fi
}

# Check if jq is installed
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq for JSON processing."
    exit 1
  fi
}

# Main script execution
echo "=== Testing Redmine API ==="
check_jq
read_credentials
echo "Using Redmine URL: $REDMINE_URL"
echo "Using Redmine API Key: ${REDMINE_API_KEY:0:5}***"
test_projects
test_issues
test_trackers
test_issue_statuses
test_issue_priorities
echo "=== All API tests passed successfully ==="