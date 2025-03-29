#!/bin/bash
# Script to test the overall robustness of the MCP extension
# This includes testing Docker compatibility and Redmine availability handling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print header
echo "🧪 MCP Extension Robustness Test"
echo "================================"
echo "Testing how the MCP extension handles various failure scenarios"
echo ""

# Check if Docker is available
command -v docker >/dev/null 2>&1 || {
    echo "❌ Docker is not installed or not in PATH. Skipping Docker tests."
    RUN_DOCKER_TESTS=false
}

# Check if the MCP extension is running
curl -s http://localhost:9000 >/dev/null 2>&1 || {
    echo "❌ MCP extension is not running. Please start it first."
    exit 1
}

# Run Docker compatibility check if available
if [ "$RUN_DOCKER_TESTS" != "false" ]; then
    echo "🐳 Running Docker compatibility check..."
    echo ""
    $SCRIPT_DIR/check_docker_compatibility.sh
    echo ""
    echo "Docker compatibility check completed."
fi

# Test Redmine availability handling
echo ""
echo "🔍 Testing MCP with unavailable Redmine..."
echo ""

# Create backup of current configuration
echo "📦 Creating backup of current configuration..."
$SCRIPT_DIR/test_redmine_availability.py --create-test-config
if [ $? -ne 0 ]; then
    echo "❌ Failed to create test configuration. Aborting."
    exit 1
fi

# Run the test
echo ""
echo "🧪 Running test with unavailable Redmine..."
$SCRIPT_DIR/test_redmine_availability.py
if [ $? -ne 0 ]; then
    echo "❌ Test failed."
else
    echo "✅ Test completed successfully."
fi

# Restore original configuration
echo ""
echo "🔄 Restoring original configuration..."
$SCRIPT_DIR/test_redmine_availability.py --restore-config
if [ $? -ne 0 ]; then
    echo "⚠️ Failed to restore original configuration. You may need to restore manually."
else
    echo "✅ Original configuration restored."
fi

# Summary
echo ""
echo "============================"
echo "🎯 Test Summary:"
echo "============================"
echo "MCP extension was tested for:"
echo "✓ Docker compatibility"
echo "✓ Handling unavailable Redmine"
echo ""
echo "⚠️ Note: You may need to restart the MCP extension to reload the configuration."
echo "You can do this with: docker restart mcp-extension-local"
echo ""