#!/bin/bash

# This script automates the setup of Redmine and an API key for testing
# It should be run after docker-compose up -d

echo "Waiting for Redmine to start up..."
until $(curl --output /dev/null --silent --head --fail http://localhost:3000); do
    printf '.'
    sleep 5
done
echo "Redmine is up and running!"

# Give Redmine a bit more time to fully initialize
sleep 10

# Check if user exists
echo "Checking if default admin user exists..."
ADMIN_EXISTS=$(curl -s http://localhost:3000/login | grep -c "admin")

if [ $ADMIN_EXISTS -gt 0 ]; then
    echo "Default admin user exists. Logging in..."
    
    # Get the authenticity token
    LOGIN_PAGE=$(curl -s -c cookies.txt http://localhost:3000/login)
    CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -o 'name="authenticity_token" value="[^"]*"' | sed 's/name="authenticity_token" value="//;s/"$//')
    
    # Login as admin
    curl -s -b cookies.txt -c cookies.txt -X POST http://localhost:3000/login \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin&password=admin&authenticity_token=$CSRF_TOKEN"
    
    # Get the my account page to navigate to API keys
    MY_ACCOUNT_PAGE=$(curl -s -b cookies.txt http://localhost:3000/my/account)
    ACCOUNT_CSRF_TOKEN=$(echo "$MY_ACCOUNT_PAGE" | grep -o 'name="authenticity_token" value="[^"]*"' | sed 's/name="authenticity_token" value="//;s/"$//')
    
    # Go to API keys page
    API_KEYS_PAGE=$(curl -s -b cookies.txt http://localhost:3000/my/api_key)
    
    # Check if an API key already exists
    if echo "$API_KEYS_PAGE" | grep -q "Your API key"; then
        echo "API key already exists."
        API_KEY=$(echo "$API_KEYS_PAGE" | grep -o 'Your API key: [^<]*' | sed 's/Your API key: //')
    else
        # Generate a new API key
        echo "Generating new API key..."
        API_KEY_PAGE_CSRF_TOKEN=$(echo "$API_KEYS_PAGE" | grep -o 'name="authenticity_token" value="[^"]*"' | sed 's/name="authenticity_token" value="//;s/"$//')
        
        RESULT=$(curl -s -b cookies.txt -c cookies.txt -X POST http://localhost:3000/my/api_key \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "authenticity_token=$API_KEY_PAGE_CSRF_TOKEN&key_action=generate")
        
        # Extract the new API key
        API_KEY=$(echo "$RESULT" | grep -o 'Your API key: [^<]*' | sed 's/Your API key: //')
    fi
    
    # Cleanup
    rm -f cookies.txt
    
    if [ -n "$API_KEY" ]; then
        echo "API Key: $API_KEY"
        
        # Create a credentials file for our application
        echo "Creating credentials.yaml file..."
        cat > credentials.yaml << EOL
redmine_url: http://localhost:3000
redmine_api_key: $API_KEY
openai_api_key: your_openai_api_key_here
rate_limit_per_minute: 60
EOL
        echo "Created credentials.yaml file with Redmine API key."
        echo "Please update the OpenAI API key with your actual key."
    else
        echo "Failed to retrieve API key."
    fi
else
    echo "Could not find admin user. Make sure Redmine is properly initialized."
fi

echo "Setup complete!"