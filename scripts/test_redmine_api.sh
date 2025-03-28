#!/bin/bash
# Test script for Redmine API connectivity

# Default values
REDMINE_URL=${REDMINE_URL:-"http://localhost:3000"}
REDMINE_API_KEY=${REDMINE_API_KEY:-""}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --url)
      REDMINE_URL="$2"
      shift 2
      ;;
    --api-key)
      REDMINE_API_KEY="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--url REDMINE_URL] [--api-key REDMINE_API_KEY]"
      echo ""
      echo "Tests connectivity to the Redmine API and performs basic operations."
      echo ""
      echo "Options:"
      echo "  --url REDMINE_URL       Redmine instance URL (default: http://localhost:3000)"
      echo "  --api-key REDMINE_API_KEY  Your Redmine API key"
      echo "  --help                  Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if API key is provided
if [[ -z "$REDMINE_API_KEY" ]]; then
  echo "❌ Error: Redmine API key is required"
  echo "Use --api-key to provide your API key or set the REDMINE_API_KEY environment variable"
  exit 1
fi

# Function to make API requests
function make_request() {
  local method=$1
  local endpoint=$2
  local data=$3
  
  if [[ -n "$data" ]]; then
    curl -s -X "$method" -H "Content-Type: application/json" -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
      -d "$data" \
      "${REDMINE_URL}/${endpoint}"
  else
    curl -s -X "$method" -H "Content-Type: application/json" -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
      "${REDMINE_URL}/${endpoint}"
  fi
}

echo "🔍 Testing Redmine API connectivity..."
echo "URL: $REDMINE_URL"

# Test 1: Get Redmine version
echo -n "Testing Redmine version... "
VERSION_RESPONSE=$(make_request "GET" "projects.json?limit=1" "")

if echo "$VERSION_RESPONSE" | grep -q "projects"; then
  echo "✅ Success!"
else
  echo "❌ Failed to connect to Redmine API"
  echo "Response: $VERSION_RESPONSE"
  exit 1
fi

# Test 2: Get projects
echo -n "Getting projects... "
PROJECTS_RESPONSE=$(make_request "GET" "projects.json" "")

if echo "$PROJECTS_RESPONSE" | grep -q "projects"; then
  echo "✅ Success!"
  PROJECTS_COUNT=$(echo "$PROJECTS_RESPONSE" | grep -o '"total_count":[0-9]*' | cut -d':' -f2)
  echo "Found $PROJECTS_COUNT projects"
  
  # Extract first project ID for further tests
  FIRST_PROJECT_ID=$(echo "$PROJECTS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
  echo "Using project ID: $FIRST_PROJECT_ID for further tests"
else
  echo "❌ Failed to get projects"
  echo "Response: $PROJECTS_RESPONSE"
  exit 1
fi

# Test 3: Get issues for the project
echo -n "Getting issues for project $FIRST_PROJECT_ID... "
ISSUES_RESPONSE=$(make_request "GET" "issues.json?project_id=$FIRST_PROJECT_ID" "")

if echo "$ISSUES_RESPONSE" | grep -q "issues"; then
  echo "✅ Success!"
  ISSUES_COUNT=$(echo "$ISSUES_RESPONSE" | grep -o '"total_count":[0-9]*' | cut -d':' -f2)
  echo "Found $ISSUES_COUNT issues"
  
  # Extract first issue ID if any
  if [[ "$ISSUES_COUNT" -gt 0 ]]; then
    FIRST_ISSUE_ID=$(echo "$ISSUES_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "First issue ID: $FIRST_ISSUE_ID"
  fi
else
  echo "❌ Failed to get issues"
  echo "Response: $ISSUES_RESPONSE"
  exit 1
fi

# Test 4: Create an issue
echo "Creating a test issue..."
ISSUE_DATA='{
  "issue": {
    "project_id": '$FIRST_PROJECT_ID',
    "subject": "Test issue from API script",
    "description": "This is a test issue created by the Redmine API test script.",
    "priority_id": 2
  }
}'

CREATE_RESPONSE=$(make_request "POST" "issues.json" "$ISSUE_DATA")

if echo "$CREATE_RESPONSE" | grep -q '"id":'; then
  echo "✅ Issue created successfully!"
  NEW_ISSUE_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
  echo "New issue ID: $NEW_ISSUE_ID"
else
  echo "❌ Failed to create issue"
  echo "Response: $CREATE_RESPONSE"
  exit 1
fi

# Test 5: Update the issue
echo "Updating the test issue..."
UPDATE_DATA='{
  "issue": {
    "notes": "This is an update from the API test script",
    "priority_id": 3
  }
}'

UPDATE_RESPONSE=$(make_request "PUT" "issues/$NEW_ISSUE_ID.json" "$UPDATE_DATA")

if [[ -z "$UPDATE_RESPONSE" ]]; then
  echo "✅ Issue updated successfully!"
else
  echo "❌ Failed to update issue"
  echo "Response: $UPDATE_RESPONSE"
  exit 1
fi

echo ""
echo "🎉 All tests passed! The Redmine API is working correctly."
echo "The following operations were verified:"
echo "✅ Connection to Redmine API"
echo "✅ Listing projects"
echo "✅ Listing issues"
echo "✅ Creating a new issue"
echo "✅ Updating an existing issue"
echo ""
echo "Created test issue ID: $NEW_ISSUE_ID"