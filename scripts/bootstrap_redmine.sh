#!/bin/bash
#
# Bootstrap Redmine Script Wrapper
# This script is a convenient wrapper for bootstrap_redmine.py
#
# Usage:
#   ./scripts/bootstrap_redmine.sh [options]
#
# Options:
#   --url=<url>         Redmine URL (default: http://localhost:3000)
#   --api-key=<key>     Redmine admin API key
#   --verbose           Show verbose output
#   --verify            Only verify setup without making changes
#

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PYTHON_SCRIPT="${SCRIPT_DIR}/bootstrap_redmine.py"
CREDENTIALS_FILE="${SCRIPT_DIR}/../credentials.yaml"

# Default values
REDMINE_URL="http://localhost:3000"
VERBOSE=""
VERIFY=""
API_KEY=""

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --url=*)
      REDMINE_URL="${arg#*=}"
      shift
      ;;
    --api-key=*)
      API_KEY="${arg#*=}"
      shift
      ;;
    --verbose)
      VERBOSE="--verbose"
      shift
      ;;
    --verify)
      VERIFY="--verify"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --url=<url>         Redmine URL (default: http://localhost:3000)"
      echo "  --api-key=<key>     Redmine admin API key"
      echo "  --verbose           Show verbose output"
      echo "  --verify            Only verify setup without making changes"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      # Unknown option
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if credentials file exists
if [ -f "$CREDENTIALS_FILE" ] && [ -z "$API_KEY" ]; then
  echo "Using credentials from $CREDENTIALS_FILE"
fi

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
  echo "Error: Bootstrap Python script not found at $PYTHON_SCRIPT"
  exit 1
fi

# Make script executable
chmod +x "$PYTHON_SCRIPT"

# Run the Python script
echo "======================================================="
echo "Starting Redmine Bootstrap Process"
echo "Redmine URL: $REDMINE_URL"
echo "======================================================="

if [ -n "$API_KEY" ]; then
  python3 "$PYTHON_SCRIPT" --url="$REDMINE_URL" --api-key="$API_KEY" $VERBOSE $VERIFY
else
  python3 "$PYTHON_SCRIPT" --url="$REDMINE_URL" --credentials="$CREDENTIALS_FILE" $VERBOSE $VERIFY
fi

exit_code=$?

if [ $exit_code -eq 0 ]; then
  echo "======================================================="
  echo "✅ Bootstrap completed successfully"
  echo "======================================================="
else
  echo "======================================================="
  echo "❌ Bootstrap failed with exit code $exit_code"
  echo "======================================================="
fi

exit $exit_code