#!/bin/bash
# Script to create and update local development credentials

set -e

REDMINE_URL=${1:-"http://localhost:3000"}
REDMINE_API_KEY=${2:-"YOUR_REDMINE_API_KEY"}
CLAUDE_API_KEY=${3:-"YOUR_CLAUDE_API_KEY"}
RATE_LIMIT=${4:-60}

echo "🔑 Setting up local credentials..."

# Function to validate URL format
validate_url() {
    # Simple URL validation (requires protocol and domain)
    if [[ ! "$1" =~ ^https?:// ]]; then
        echo "❌ ERROR: Invalid URL format: $1"
        echo "URL must start with http:// or https://"
        exit 1
    fi
}

# Create credentials.yaml file
create_credentials_file() {
    validate_url "$REDMINE_URL"
    
    echo "⚙️ Creating credentials.yaml file..."
    cat > credentials.yaml << EOF
# Redmine MCP Extension Credentials
redmine:
  url: ${REDMINE_URL}
  api_key: ${REDMINE_API_KEY}

claude:
  api_key: ${CLAUDE_API_KEY}

# Rate limit (calls per minute)
rate_limit: ${RATE_LIMIT}
EOF
    echo "✅ Created credentials.yaml file"
}

# Check if credentials.yaml already exists
if [ -f "credentials.yaml" ]; then
    echo "⚠️ credentials.yaml already exists."
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        create_credentials_file
    else
        echo "ℹ️ Using existing credentials.yaml file"
    fi
else
    create_credentials_file
fi

echo "
🔑 Credential setup complete!

✨ Next steps:
   1. Make sure Redmine is running at ${REDMINE_URL}
   2. Add your actual API keys to credentials.yaml:
      - Redmine API key: Get from Redmine > My account > API access key
      - Claude API key: Get from Anthropic dashboard
   3. Start the application with: flask run --host=0.0.0.0 --port=5000
"