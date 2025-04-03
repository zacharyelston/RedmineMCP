#!/bin/bash
# test.sh - Local test runner for Redmine-MCP

# Parse arguments
TEST_TYPE=${1:-"all"}
COVERAGE=${2:-"false"}

# Set up environment
echo "Setting up test environment..."
python -m pip install -r requirements.txt
python -m pip install pytest pytest-cov

# Set up test config if needed
if [ ! -f "credentials.yaml" ]; then
  cp credentials.yaml.example credentials.yaml
  sed -i 's/redmine_api_key:.*/redmine_api_key: test_api_key/g' credentials.yaml
  sed -i 's/llm_provider:.*/llm_provider: mock/g' credentials.yaml
fi

# Create test directories if they don't exist
mkdir -p tests/unit tests/integration

# Run tests based on type
case $TEST_TYPE in
  "unit")
    echo "Running unit tests..."
    if [ "$COVERAGE" = "true" ]; then
      pytest tests/unit --cov=. --cov-report=term
    else
      pytest tests/unit
    fi
    ;;
  "integration")
    echo "Running integration tests..."
    if [ "$COVERAGE" = "true" ]; then
      pytest tests/integration --cov=. --cov-report=term
    else
      pytest tests/integration
    fi
    ;;
  "all")
    echo "Running all tests..."
    if [ "$COVERAGE" = "true" ]; then
      pytest tests --cov=. --cov-report=term
    else
      pytest tests
    fi
    ;;
  *)
    echo "Unknown test type: $TEST_TYPE"
    echo "Usage: ./test.sh [unit|integration|all] [true|false]"
    exit 1
    ;;
esac
