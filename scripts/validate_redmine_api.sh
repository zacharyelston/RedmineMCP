#!/bin/bash
# Simple wrapper script to run the Redmine API validation tests

# Set default variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDMINE_URL=${REDMINE_URL:-"http://localhost:3000"}
CREDENTIALS_PATH="${SCRIPT_DIR}/../credentials.yaml"
CLEANUP=${CLEANUP:-"false"}
VERBOSE=${VERBOSE:-"false"}

# Display script banner
echo "======================================================"
echo "  Redmine API Validation Tool"
echo "======================================================"
echo "This script tests if the Redmine API is functioning correctly"
echo "by creating test projects, issues, and other entities."
echo

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --redmine-url=*)
      REDMINE_URL="${1#*=}"
      shift
      ;;
    --api-key=*)
      API_KEY="${1#*=}"
      shift
      ;;
    --credentials=*)
      CREDENTIALS_PATH="${1#*=}"
      shift
      ;;
    --cleanup)
      CLEANUP="true"
      shift
      ;;
    --verbose|-v)
      VERBOSE="true"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo
      echo "Options:"
      echo "  --redmine-url=URL     Redmine server URL (default: $REDMINE_URL)"
      echo "  --api-key=KEY         Redmine API key (overrides credentials file)"
      echo "  --credentials=PATH    Path to credentials.yaml file"
      echo "  --cleanup             Clean up test resources after running"
      echo "  --verbose, -v         Enable verbose output"
      echo "  --help, -h            Show this help message"
      echo
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
  echo "Error: Python 3 is required but not installed."
  exit 1
fi

# Check if credentials file exists when no API key is provided
if [ -z "$API_KEY" ] && [ ! -f "$CREDENTIALS_PATH" ]; then
  echo "Error: Credentials file not found at $CREDENTIALS_PATH and no API key provided."
  echo "Please provide an API key with --api-key or create a credentials.yaml file."
  exit 1
fi

# Build the command
CMD="python3 ${SCRIPT_DIR}/test_redmine_api_functionality.py --redmine-url $REDMINE_URL"

if [ -n "$API_KEY" ]; then
  CMD="$CMD --api-key $API_KEY"
else
  CMD="$CMD --credentials $CREDENTIALS_PATH"
fi

if [ "$CLEANUP" = "true" ]; then
  CMD="$CMD --cleanup"
fi

if [ "$VERBOSE" = "true" ]; then
  CMD="$CMD --verbose"
fi

# Run the Python script
echo "Running validation with the following settings:"
echo "  - Redmine URL: $REDMINE_URL"
echo "  - Credentials file: ${API_KEY:+[API key provided via command line]}"
echo "  - Credentials file: ${API_KEY:-$CREDENTIALS_PATH}"
echo "  - Cleanup after test: $CLEANUP"
echo "  - Verbose output: $VERBOSE"
echo
echo "Starting test..."
echo "======================================================"

$CMD
EXIT_CODE=$?

echo "======================================================"
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ Validation completed successfully!"
else
  echo "❌ Validation failed with exit code $EXIT_CODE"
fi
echo "======================================================"

exit $EXIT_CODE