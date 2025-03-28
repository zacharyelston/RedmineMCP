#!/bin/bash
# Shell script to test Redmine API connectivity

set -e

REDMINE_URL="${REDMINE_URL:-http://localhost:3000}"
REDMINE_API_KEY="${REDMINE_API_KEY:-}"
VERBOSE="${VERBOSE:-false}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)
            REDMINE_URL="$2"
            shift 2
            ;;
        --api-key)
            REDMINE_API_KEY="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --url URL             Redmine URL (default: http://localhost:3000)"
            echo "  --api-key KEY         Redmine API key"
            echo "  --verbose             Enable verbose output"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Try to get API key from credentials.yaml if not provided
if [ -z "$REDMINE_API_KEY" ] && [ -f credentials.yaml ]; then
    echo "No API key provided, attempting to read from credentials.yaml..."
    if command -v yq &> /dev/null; then
        REDMINE_API_KEY=$(yq -r '.redmine.api_key' credentials.yaml)
    elif command -v python3 &> /dev/null; then
        REDMINE_API_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('credentials.yaml', 'r'))['redmine']['api_key'])")
    else
        echo "Error: Could not read API key from credentials.yaml. Install yq or python3-yaml."
        exit 1
    fi
fi

# Check if API key is provided
if [ -z "$REDMINE_API_KEY" ]; then
    echo "Error: No Redmine API key provided. Please provide it using --api-key or set REDMINE_API_KEY."
    exit 1
fi

# Function to make API requests with proper headers
make_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    
    if [ "$VERBOSE" = true ]; then
        echo "Making $method request to $REDMINE_URL/$endpoint"
    fi
    
    response=$(curl -s -X "$method" \
        -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
        -H "Content-Type: application/json" \
        "$REDMINE_URL/$endpoint")
    
    if [ "$VERBOSE" = true ]; then
        echo "Response:"
        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
    
    echo "$response"
}

echo "Testing Redmine API connection to $REDMINE_URL..."

# Test 1: Check if we can connect and authenticate
echo "Test 1: Checking authentication..."
projects_response=$(make_request "projects.json")

if echo "$projects_response" | grep -q "total_count"; then
    echo "✅ Authentication successful!"
else
    echo "❌ Authentication failed. Response:"
    echo "$projects_response" | jq . 2>/dev/null || echo "$projects_response"
    exit 1
fi

# Test 2: Try to fetch issues
echo "Test 2: Fetching issues..."
issues_response=$(make_request "issues.json?limit=1")

if echo "$issues_response" | grep -q "total_count"; then
    echo "✅ Successfully fetched issues!"
else
    echo "❌ Failed to fetch issues. Response:"
    echo "$issues_response" | jq . 2>/dev/null || echo "$issues_response"
    exit 1
fi

# Test 3: Create a test issue
echo "Test 3: Creating a test issue..."
project_id=$(echo "$projects_response" | jq -r '.projects[0].id' 2>/dev/null)

if [ -z "$project_id" ] || [ "$project_id" = "null" ]; then
    echo "❌ Could not find any projects to create an issue in."
    exit 1
fi

create_issue_json='{
    "issue": {
        "project_id": "'$project_id'",
        "subject": "Test issue created by API test script",
        "description": "This is a test issue created by the Redmine API test script at '$(date)'."
    }
}'

create_response=$(curl -s -X POST \
    -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$create_issue_json" \
    "$REDMINE_URL/issues.json")

issue_id=$(echo "$create_response" | jq -r '.issue.id' 2>/dev/null)

if [ -n "$issue_id" ] && [ "$issue_id" != "null" ]; then
    echo "✅ Successfully created test issue with ID: $issue_id"
else
    echo "❌ Failed to create test issue. Response:"
    echo "$create_response" | jq . 2>/dev/null || echo "$create_response"
    exit 1
fi

echo "🎉 All Redmine API tests passed successfully!"