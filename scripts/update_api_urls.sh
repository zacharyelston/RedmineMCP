#!/bin/bash

# This script updates the application's configuration to use a local Redmine instance
# It should be run when you want to test against the Docker container

# Function to read the current credentials file
read_credentials() {
  if [ -f "credentials.yaml" ]; then
    echo "Reading current credentials from credentials.yaml..."
    REDMINE_URL=$(grep "redmine_url:" credentials.yaml | awk '{print $2}')
    REDMINE_API_KEY=$(grep "redmine_api_key:" credentials.yaml | awk '{print $2}')
    OPENAI_API_KEY=$(grep "openai_api_key:" credentials.yaml | awk '{print $2}')
    RATE_LIMIT=$(grep "rate_limit_per_minute:" credentials.yaml | awk '{print $2}')
  else
    echo "No credentials.yaml file found. Using default values..."
    REDMINE_URL="http://localhost:3000"
    REDMINE_API_KEY="your_redmine_api_key_here"
    OPENAI_API_KEY="your_openai_api_key_here"
    RATE_LIMIT=60
  fi
}

# Function to update the credentials file
update_credentials() {
  echo "Updating credentials for local testing..."
  
  read -p "Enter local Redmine URL [http://localhost:3000]: " new_url
  REDMINE_URL=${new_url:-http://localhost:3000}
  
  read -p "Enter Redmine API key: " new_api_key
  if [ -n "$new_api_key" ]; then
    REDMINE_API_KEY=$new_api_key
  fi
  
  read -p "Enter OpenAI API key: " new_openai_key
  if [ -n "$new_openai_key" ]; then
    OPENAI_API_KEY=$new_openai_key
  fi
  
  read -p "Enter rate limit per minute [60]: " new_rate_limit
  RATE_LIMIT=${new_rate_limit:-60}
  
  # Create the updated credentials file
  cat > credentials.yaml << EOL
redmine_url: $REDMINE_URL
redmine_api_key: $REDMINE_API_KEY
openai_api_key: $OPENAI_API_KEY
rate_limit_per_minute: $RATE_LIMIT
EOL
  
  echo "Updated credentials.yaml file for local testing."
  echo "You may need to restart the application for changes to take effect."
}

# Main script execution
echo "=== Updating RedmineMCP Configuration for Local Testing ==="
read_credentials
update_credentials
echo "=== Configuration updated ==="