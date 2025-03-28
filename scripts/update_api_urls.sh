#!/bin/bash
# Script to update API URLs in the Redmine MCP Extension

# Default values
NEW_REDMINE_URL=""
NEW_CLAUDE_URL=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --redmine-url)
      NEW_REDMINE_URL="$2"
      shift 2
      ;;
    --claude-url)
      NEW_CLAUDE_URL="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--redmine-url NEW_REDMINE_URL] [--claude-url NEW_CLAUDE_URL]"
      echo ""
      echo "Updates API URLs in the Redmine MCP Extension."
      echo ""
      echo "Options:"
      echo "  --redmine-url NEW_REDMINE_URL   New Redmine API URL"
      echo "  --claude-url NEW_CLAUDE_URL     New Claude API URL"
      echo "  --help                          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate inputs
if [[ -z "$NEW_REDMINE_URL" && -z "$NEW_CLAUDE_URL" ]]; then
  echo "❌ Error: At least one URL must be provided"
  echo "Use --redmine-url or --claude-url to specify the new URL(s)"
  exit 1
fi

# Check for credentials file
if [[ ! -f "credentials.yaml" ]]; then
  echo "❌ Error: credentials.yaml file not found"
  echo "Please create the file first using 'cp credentials.yaml.example credentials.yaml'"
  exit 1
fi

# Update Redmine URL in credentials.yaml
if [[ -n "$NEW_REDMINE_URL" ]]; then
  echo "Updating Redmine URL to: $NEW_REDMINE_URL"
  
  # Check if the URL has the correct format
  if [[ ! "$NEW_REDMINE_URL" =~ ^https?:// ]]; then
    echo "⚠️ Warning: The Redmine URL should start with http:// or https://"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 0
    fi
  fi
  
  # Update the URL in credentials.yaml
  if grep -q "redmine_url:" credentials.yaml; then
    sed -i.bak "s|redmine_url:.*|redmine_url: '$NEW_REDMINE_URL'|" credentials.yaml
    echo "✅ Updated Redmine URL in credentials.yaml"
  else
    echo "⚠️ Warning: redmine_url entry not found in credentials.yaml"
    echo "Please check the file format and try again"
  fi
fi

# Update Claude API URL in llm_api.py
if [[ -n "$NEW_CLAUDE_URL" ]]; then
  echo "Updating Claude API URL to: $NEW_CLAUDE_URL"
  
  # Check if the URL has the correct format
  if [[ ! "$NEW_CLAUDE_URL" =~ ^https?:// ]]; then
    echo "⚠️ Warning: The Claude API URL should start with http:// or https://"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 0
    fi
  fi
  
  # Update the URL in llm_api.py
  if [[ -f "llm_api.py" ]]; then
    if grep -q "API_URL =" llm_api.py; then
      sed -i.bak "s|API_URL = .*|API_URL = \"$NEW_CLAUDE_URL\"|" llm_api.py
      echo "✅ Updated Claude API URL in llm_api.py"
    else
      echo "⚠️ Warning: API_URL entry not found in llm_api.py"
      echo "Please check the file format and try again"
    fi
  else
    echo "❌ Error: llm_api.py file not found"
  fi
fi

# Clean up backup files
find . -name "*.bak" -type f -delete

echo ""
echo "🎉 API URLs updated successfully."
echo "You may need to restart the application for changes to take effect."