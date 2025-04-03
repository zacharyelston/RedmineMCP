#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up development environment for Redmine MCP Extension...${NC}"

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p logs
mkdir -p storage

# Start containers in background
echo -e "${GREEN}Starting Redmine, PostgreSQL, and MCP Extension containers...${NC}"
docker-compose -f docker-compose.dev.yml up -d db redmine

# Wait for Redmine to start up (it can take a minute or two)
echo -e "${YELLOW}Waiting for Redmine to start up (this may take a few minutes)...${NC}"
until $(curl --output /dev/null --silent --head --fail http://localhost:3000); do
    printf '.'
    sleep 5
done

echo -e "\n${GREEN}Redmine is up and running!${NC}"

# Instructions for manual steps to get API key
echo -e "${YELLOW}Now you need to create an API key in Redmine:${NC}"
echo -e "1. Open http://localhost:3000 in your browser"
echo -e "2. Log in with default credentials: admin/admin"
echo -e "3. Go to Administration > Settings > API"
echo -e "4. Enable the 'Enable REST web service' option and save"
echo -e "5. Go to My account > API access key and click 'Show' to reveal your API key"
echo -e "6. Copy this key for the next step"

# Prompt for API key input
read -p "Enter your Redmine API key: " api_key

# Update docker-compose file with the API key
sed -i "s/REDMINE_API_KEY=GENERATED_API_KEY/REDMINE_API_KEY=$api_key/" docker-compose.dev.yml

# Restart MCP Extension container with the new API key
echo -e "${GREEN}Starting MCP Extension with your API key...${NC}"
docker-compose -f docker-compose.dev.yml up -d mcp_extension

echo -e "${GREEN}Development environment setup complete!${NC}"
echo -e "Redmine is running at: http://localhost:3000"
echo -e "MCP Extension is running at: http://localhost:9000"
echo -e "\n${YELLOW}You can view logs with:${NC}"
echo -e "  docker-compose -f docker-compose.dev.yml logs -f redmine"
echo -e "  docker-compose -f docker-compose.dev.yml logs -f mcp_extension"