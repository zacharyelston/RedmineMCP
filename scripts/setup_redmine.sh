#!/bin/bash

# Script to set up a local Redmine instance for testing

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required but not installed."
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is required but not installed."
    echo "Please install Docker Compose first: https://docs.docker.com/compose/install/"
    exit 1
fi

# Create a directory for Redmine data if it doesn't exist
mkdir -p redmine_data

# Create a docker-compose file for Redmine
cat > docker-compose.yml << 'EOL'
version: '3'

services:
  redmine:
    image: redmine:5.0
    restart: always
    ports:
      - "3000:3000"
    environment:
      REDMINE_DB_POSTGRES: redmine_db
      REDMINE_DB_USERNAME: redmine
      REDMINE_DB_PASSWORD: redmine_password
      REDMINE_DB_DATABASE: redmine
      REDMINE_SECRET_KEY_BASE: supersecretkey123
    volumes:
      - ./redmine_data:/usr/src/redmine/files
    depends_on:
      - redmine_db

  redmine_db:
    image: postgres:14
    restart: always
    environment:
      POSTGRES_PASSWORD: redmine_password
      POSTGRES_USER: redmine
      POSTGRES_DB: redmine
    volumes:
      - ./redmine_data/postgres:/var/lib/postgresql/data
EOL

echo "Starting Redmine with Docker Compose..."
docker-compose up -d

echo "Waiting for Redmine to start up (this may take a minute)..."
sleep 30

echo "Redmine should now be running at http://localhost:3000"
echo "Default login credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Please follow these steps to complete the setup:"
echo "1. Log in with admin/admin"
echo "2. Go to Administration > Settings > API"
echo "3. Enable the REST API"
echo "4. Go to My Account > API access key"
echo "5. Generate a new API key"
echo "6. Copy the API key and use it in your credentials.yaml file"