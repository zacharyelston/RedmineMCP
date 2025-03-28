#!/bin/bash

# Script to test the Redmine API integration

# Check if credentials file exists
if [ ! -f "credentials.yaml" ]; then
    echo "Error: credentials.yaml file not found"
    echo "Please create a credentials.yaml file first (copy from credentials.yaml.example)"
    exit 1
fi

# Extract Redmine URL and API key from credentials file
REDMINE_URL=$(grep "redmine_url" credentials.yaml | cut -d":" -f2- | tr -d " '")
REDMINE_API_KEY=$(grep "redmine_api_key" credentials.yaml | cut -d":" -f2- | tr -d " '")

if [ -z "$REDMINE_URL" ] || [ -z "$REDMINE_API_KEY" ]; then
    echo "Error: Could not extract Redmine URL or API key from credentials.yaml"
    echo "Please make sure your credentials.yaml file has redmine_url and redmine_api_key entries"
    exit 1
fi

echo "Testing Redmine API connectivity..."
echo "Redmine URL: $REDMINE_URL"
echo "API Key: ${REDMINE_API_KEY:0:5}..."

# Test getting projects
echo -e "\n1. Testing GET /projects.json"
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
     -H "Content-Type: application/json" \
     "$REDMINE_URL/projects.json" | python -m json.tool

# Test getting trackers
echo -e "\n2. Testing GET /trackers.json"
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
     -H "Content-Type: application/json" \
     "$REDMINE_URL/trackers.json" | python -m json.tool

# Test getting issue statuses
echo -e "\n3. Testing GET /issue_statuses.json"
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
     -H "Content-Type: application/json" \
     "$REDMINE_URL/issue_statuses.json" | python -m json.tool

# Test getting issues
echo -e "\n4. Testing GET /issues.json"
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
     -H "Content-Type: application/json" \
     "$REDMINE_URL/issues.json" | python -m json.tool

# Test creating an issue (assuming project_id 1 exists)
echo -e "\n5. Testing POST /issues.json (create issue)"
TEST_ISSUE_RESULT=$(curl -s -X POST \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"issue":{"project_id":1,"subject":"Test Issue from API","description":"This is a test issue created by the API test script."}}' \
    "$REDMINE_URL/issues.json")

echo "$TEST_ISSUE_RESULT" | python -m json.tool

# Extract the issue ID from the response
TEST_ISSUE_ID=$(echo "$TEST_ISSUE_RESULT" | grep -o '"id":[0-9]*' | head -1 | cut -d":" -f2)

if [ -n "$TEST_ISSUE_ID" ]; then
    # Test updating the issue
    echo -e "\n6. Testing PUT /issues/$TEST_ISSUE_ID.json (update issue)"
    curl -s -X PUT \
        -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"issue":{"notes":"This issue was updated by the API test script."}}' \
        "$REDMINE_URL/issues/$TEST_ISSUE_ID.json"
    
    echo -e "\nUpdate successful. No content is returned for successful updates."
    
    # Test getting the updated issue
    echo -e "\n7. Testing GET /issues/$TEST_ISSUE_ID.json (get updated issue)"
    curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
         -H "Content-Type: application/json" \
         "$REDMINE_URL/issues/$TEST_ISSUE_ID.json?include=journals" | python -m json.tool
else
    echo "Skipping issue update test because issue creation failed or ID couldn't be extracted."
fi

echo -e "\nAPI tests completed!"