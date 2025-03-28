#!/bin/bash

# Script to set up local credentials for the Redmine MCP Extension

set -e

CREDENTIALS_FILE="./credentials.yaml"
EXAMPLE_FILE="./credentials.yaml.example"

echo "🔑 Setting up credentials for local development..."

# Check if credentials file already exists
if [ -f "$CREDENTIALS_FILE" ]; then
  read -p "⚠️ credentials.yaml already exists. Overwrite? (y/n): " overwrite
  if [[ "$overwrite" != "y" ]]; then
    echo "❌ Aborted. Existing credentials file not modified."
    exit 0
  fi
fi

# Check if example file exists
if [ ! -f "$EXAMPLE_FILE" ]; then
  echo "❌ ERROR: credentials.yaml.example not found. Cannot create configuration."
  exit 1
fi

# Create credentials file from example
cp "$EXAMPLE_FILE" "$CREDENTIALS_FILE"
echo "✅ Created credentials.yaml from example file."

# Open credentials file for editing
if command -v nano >/dev/null 2>&1; then
  echo "📝 Opening credentials file for editing with nano..."
  nano "$CREDENTIALS_FILE"
elif command -v vim >/dev/null 2>&1; then
  echo "📝 Opening credentials file for editing with vim..."
  vim "$CREDENTIALS_FILE"
else
  echo "⚠️ No editor found (nano or vim). Please manually edit $CREDENTIALS_FILE"
  echo "📋 Instructions:"
  echo "   1. Log into Redmine at http://localhost:3000 (admin/admin)"
  echo "   2. Go to My account > API access key"
  echo "   3. Click 'Show' to view your API key"
  echo "   4. Copy the key and add it to credentials.yaml"
  echo "   5. Add your Claude API key (get one from https://console.anthropic.com/)"
fi

echo "
🔴 Important Next Steps:
   1. For the Redmine API key:
      - Log into Redmine at http://localhost:3000 (default: admin/admin)
      - Go to 'My account' in the top right
      - Click on the 'API access key' section
      - Click 'Show' to view your key or 'Reset' to generate a new one
      - Copy this key to 'redmine_api_key' in credentials.yaml

   2. For the Claude API key:
      - Sign up/login at https://console.anthropic.com/
      - Go to 'API Keys' and create a new key
      - Copy this key to 'claude_api_key' in credentials.yaml

   3. After updating credentials, restart the MCP Extension:
      - If using docker-compose: docker restart mcp-extension-local
      - If running locally: restart the Flask application
"