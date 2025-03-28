#!/bin/bash
# Script to set up a local Redmine instance for development and automatically
# generate an API key for use with the Redmine MCP Extension

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

status "Setting up a local Redmine instance for development..."

# Check if the container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^redmine-dev$"; then
    warning "A container named 'redmine-dev' already exists"
    read -p "Do you want to remove it and create a new one? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        status "Removing existing container..."
        docker stop redmine-dev &>/dev/null
        docker rm redmine-dev &>/dev/null
    else
        status "Starting existing container..."
        docker start redmine-dev &>/dev/null
        success "Existing Redmine container started"
        echo
        echo -e "Redmine is now available at: ${GREEN}http://localhost:3000${NC}"
        echo -e "Default admin credentials: ${GREEN}admin/admin${NC}"
        exit 0
    fi
fi

# Create a standalone Redmine Docker container for quick testing
status "Creating and starting Redmine container..."
docker run --name redmine-dev \
  -d \
  -p 3000:3000 \
  -e REDMINE_DB_SQLITE=/redmine/db/sqlite/redmine.db \
  -v redmine-dev-files:/usr/src/redmine/files \
  redmine:5.0 >/dev/null

if [ $? -ne 0 ]; then
    error "Failed to start Redmine container"
    echo "Check if port 3000 is already in use or if there's another issue with Docker"
    exit 1
fi

# Wait for Redmine to start
status "Waiting for Redmine to start (this may take up to 60 seconds)..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        success "Redmine is ready!"
        break
    fi
    sleep 2
    echo -n "."
    if [ $i -eq 30 ]; then
        echo ""
        error "Redmine did not start successfully within the timeout period"
        echo "Check Docker logs with: docker logs redmine-dev"
        exit 1
    fi
done

# Generate a random API key for development
status "Generating API key for development..."
API_KEY=$(openssl rand -hex 20)

# Write the API key to the credentials file
CREDENTIALS_FILE="../credentials.yaml"
CREDENTIALS_EXAMPLE="../credentials.yaml.example"

# Check if we're running from scripts directory or project root
if [ ! -f "$CREDENTIALS_FILE" ] && [ -f "credentials.yaml" ]; then
    CREDENTIALS_FILE="credentials.yaml"
    CREDENTIALS_EXAMPLE="credentials.yaml.example"
fi

if [ -f "$CREDENTIALS_FILE" ]; then
    # Backup the existing credentials file
    cp "$CREDENTIALS_FILE" "${CREDENTIALS_FILE}.bak"
    status "Backed up existing credentials file to ${CREDENTIALS_FILE}.bak"
    
    # Update the API key in the credentials file
    sed -i.tmp "s/redmine_api_key: '.*'/redmine_api_key: '$API_KEY'/" "$CREDENTIALS_FILE"
    rm -f "${CREDENTIALS_FILE}.tmp"
    success "Updated API key in $CREDENTIALS_FILE"
elif [ -f "$CREDENTIALS_EXAMPLE" ]; then
    # Create a new credentials file from the example
    cp "$CREDENTIALS_EXAMPLE" "$CREDENTIALS_FILE"
    sed -i.tmp "s/redmine_api_key: '.*'/redmine_api_key: '$API_KEY'/" "$CREDENTIALS_FILE"
    rm -f "${CREDENTIALS_FILE}.tmp"
    success "Created new credentials file with generated API key"
else
    warning "Could not find credentials.yaml or credentials.yaml.example"
    echo "You'll need to manually add the generated API key to your configuration"
fi

# Automatically create REST API settings in Redmine
status "Configuring Redmine for REST API access..."
docker exec -it redmine-dev bash -c "
    echo 'Enabling REST API in Redmine settings...'
    sqlite3 /redmine/db/sqlite/redmine.db \"UPDATE settings SET value='---\\nrest_api_enabled: 1' WHERE name='rest_api_enabled';\"
    echo 'Creating API key for admin user...'
    sqlite3 /redmine/db/sqlite/redmine.db \"UPDATE users SET api_key='${API_KEY}' WHERE login='admin';\"
"

success "Redmine setup complete!"
echo
echo "================================================================"
echo -e "Redmine is now available at: ${GREEN}http://localhost:3000${NC}"
echo -e "Default admin credentials: ${GREEN}admin/admin${NC}"
echo -e "API key for admin user: ${GREEN}${API_KEY}${NC}"
echo
echo "This API key has been automatically added to your credentials.yaml file"
echo "================================================================"
echo 
echo "Quick commands:"
echo -e "  ${YELLOW}docker stop redmine-dev${NC}    - Stop the Redmine container"
echo -e "  ${YELLOW}docker start redmine-dev${NC}   - Start the Redmine container again"
echo -e "  ${YELLOW}docker logs redmine-dev${NC}    - View Redmine logs"
echo -e "  ${YELLOW}docker rm -f redmine-dev${NC}   - Remove the Redmine container"