#!/bin/bash

# Test script for Redmine MCP Extension integration
# This script tests if the MCP integration is properly configured

echo "=== Testing Redmine MCP Extension Integration ==="
echo ""

# First check if the extension is running
MCP_URL="http://localhost:5000"
echo "Testing MCP extension availability at $MCP_URL..."

if curl -s --head --fail "$MCP_URL" > /dev/null; then
    echo "✅ MCP extension is running!"
else
    echo "❌ MCP extension is not running at $MCP_URL"
    echo "Please start the MCP extension using 'python main.py'"
    exit 1
fi

# Check capabilities endpoint (standard MCP endpoint)
echo ""
echo "Testing MCP capabilities endpoint..."
CAPABILITIES_URL="$MCP_URL/api/capabilities"

CAPABILITIES=$(curl -s $CAPABILITIES_URL)
if [ $? -eq 0 ] && [ -n "$CAPABILITIES" ]; then
    echo "✅ MCP capabilities endpoint is accessible!"
    echo "Capabilities response:"
    echo "$CAPABILITIES" | jq . 2>/dev/null || echo "$CAPABILITIES"
else
    echo "❌ Failed to access MCP capabilities endpoint"
    echo "Response: $CAPABILITIES"
    exit 1
fi

# Check health endpoint
echo ""
echo "Testing MCP health endpoint..."
HEALTH_URL="$MCP_URL/api/health"

HEALTH=$(curl -s $HEALTH_URL)
if [ $? -eq 0 ] && [ -n "$HEALTH" ]; then
    echo "✅ MCP health endpoint is accessible!"
    echo "Health response:"
    echo "$HEALTH" | jq . 2>/dev/null || echo "$HEALTH"
    
    # Extract status from health response
    STATUS=$(echo "$HEALTH" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" == "healthy" ]; then
        echo "✅ MCP extension is healthy!"
    elif [ "$STATUS" == "warning" ]; then
        echo "⚠️ MCP extension is running with warnings"
        echo "Check the health response for details"
    else
        echo "❌ MCP extension is not healthy"
        echo "Check the health response for details"
    fi
else
    echo "❌ Failed to access MCP health endpoint"
    echo "Response: $HEALTH"
    exit 1
fi

echo ""
echo "=== MCP Integration Test Complete ==="
echo "Your Redmine MCP Extension is properly configured and accessible via MCP."
echo "Add this extension to Claude Desktop by updating your Claude Desktop configuration."
echo ""
echo "Remember to update your desktop_config.json with your actual Redmine API key."