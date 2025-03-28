#!/bin/bash

# Script to set up the Claude API key for the Redmine MCP Extension
# Note: The Redmine API key is now automatically set up with scripts/setup_redmine.sh

# Color codes for better output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

set -e

CREDENTIALS_FILE="./credentials.yaml"
EXAMPLE_FILE="./credentials.yaml.example"

status "Setting up Claude API credentials for the Redmine MCP Extension..."

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    if [ -f "$EXAMPLE_FILE" ]; then
        # Create from example if it doesn't exist
        cp "$EXAMPLE_FILE" "$CREDENTIALS_FILE"
        success "Created credentials.yaml from example file"
    else
        error "credentials.yaml.example not found. Cannot create configuration"
        exit 1
    fi
fi

# Read the current Claude API key if it exists
current_key=""
if grep -q "claude_api_key:" "$CREDENTIALS_FILE"; then
    current_key=$(grep "claude_api_key:" "$CREDENTIALS_FILE" | sed "s/claude_api_key: '//g" | sed "s/'//g")
    if [ "$current_key" != "your_claude_api_key_here" ]; then
        warning "Claude API key already set in credentials.yaml"
        read -p "Do you want to replace it? (y/n): " replace
        if [[ "$replace" != "y" ]]; then
            success "Existing Claude API key retained"
            exit 0
        fi
    fi
fi

# Ask for Claude API key
echo
echo -e "${YELLOW}=============== Claude API Setup ===============${NC}"
echo "The LLM functionality requires a Claude API key."
echo "You can get one from https://console.anthropic.com/"
echo
read -p "Enter your Claude API key: " claude_api_key

if [[ -z "$claude_api_key" ]]; then
    warning "No Claude API key provided. LLM functionality will be disabled"
    read -p "Continue anyway? (y/n): " continue_anyway
    if [[ "$continue_anyway" != "y" ]]; then
        error "Setup aborted"
        exit 1
    fi
    # Keep the placeholder value
    claude_api_key="your_claude_api_key_here"
    warning "Using placeholder value. LLM features will not work until a valid key is added"
else
    success "Claude API key received"
fi

# Update the Claude API key in the credentials file
if grep -q "claude_api_key:" "$CREDENTIALS_FILE"; then
    # If the key already exists, replace it
    sed -i.bak "s|claude_api_key: '.*'|claude_api_key: '$claude_api_key'|" "$CREDENTIALS_FILE"
    rm -f "${CREDENTIALS_FILE}.bak"
else
    # If the key doesn't exist, append it
    echo "claude_api_key: '$claude_api_key'" >> "$CREDENTIALS_FILE"
fi

success "Updated Claude API key in credentials.yaml"

echo
echo -e "${GREEN}=================== Setup Complete ===================${NC}"
echo -e "You can now use the Redmine MCP Extension with Claude AI!"
echo
echo -e "Remember to restart the MCP Extension for the changes to take effect:"
echo -e "  ${YELLOW}docker restart mcp-extension-local${NC}    (if using Docker)"
echo -e "  or restart the Flask application        (if running locally)"
echo
if [ "$claude_api_key" == "your_claude_api_key_here" ]; then
    warning "NOTE: You have not set a valid Claude API key. LLM features will be disabled"
    echo "You can add a valid key later by editing credentials.yaml directly"
fi