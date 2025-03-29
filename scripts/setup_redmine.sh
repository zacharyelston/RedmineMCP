#!/bin/bash
# Script to set up Redmine and configure credentials for local development

set -e

REDMINE_URL="http://localhost:3000"
REDMINE_API_KEY="local_dev_api_key"
CLAUDE_API_KEY_PLACEHOLDER="YOUR_CLAUDE_API_KEY"

echo "🚀 Setting up Redmine for local development..."

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker is not installed or not in PATH. Please install Docker first."
    exit 1
fi

# Check for docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ ERROR: docker-compose is not installed or not in PATH. Please install docker-compose first."
    exit 1
fi

# Check if docker is running
if ! docker info &> /dev/null; then
    echo "❌ ERROR: Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Create credentials file from example or template
if [ ! -f ./credentials.yaml ]; then
    if [ -f ./credentials.yaml.example ]; then
        echo "⚙️ Creating credentials.yaml from example file..."
        cp ./credentials.yaml.example ./credentials.yaml
    else
        echo "⚙️ Creating credentials.yaml from scratch..."
        cat > ./credentials.yaml << EOF
# Redmine MCP Extension Credentials
redmine:
  url: ${REDMINE_URL}
  api_key: ${REDMINE_API_KEY}

claude:
  api_key: ${CLAUDE_API_KEY_PLACEHOLDER}

# Rate limit (calls per minute)
rate_limit: 60
EOF
    fi
    echo "✅ Created credentials.yaml"
else
    echo "ℹ️ Using existing credentials.yaml file"
fi

# Update credentials with Redmine URL and API key for local dev
if grep -q "YOUR_REDMINE_URL\|YOUR_REDMINE_API_KEY" ./credentials.yaml; then
    echo "🔄 Updating Redmine credentials for local development..."
    sed -i.bak "s|url:.*|url: ${REDMINE_URL}|g" ./credentials.yaml
    sed -i.bak "s|api_key:.*redmine.*|api_key: ${REDMINE_API_KEY}|g" ./credentials.yaml
    rm -f ./credentials.yaml.bak
    echo "✅ Updated Redmine credentials"
fi

# Start Docker containers
echo "🏗️ Starting Docker containers..."
# First remove any existing containers to avoid the 'ContainerConfig' KeyError on ARM64
docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
docker rm -f redmine-local 2>/dev/null || true

# Start with --force-recreate to avoid volume issues on ARM64
docker-compose -f docker-compose.local.yml up -d --build --force-recreate

# Wait for Redmine to start
echo "⏳ Waiting for Redmine to be ready (this may take a minute)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Redmine is up and running!"
        break
    fi
    attempt=$((attempt+1))
    echo "⏳ Waiting for Redmine... ($attempt/$max_attempts)"
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Timed out waiting for Redmine to start. Check container logs with: docker logs redmine-local"
    exit 1
fi

# Configure Redmine for testing
echo "⚙️ Configuring Redmine with API access..."
docker exec redmine-local bash -c 'bundle exec rake redmine:plugins:migrate RAILS_ENV=production && bundle exec rake generate_secret_token' || {
    echo "⚠️ Warning: Could not run Redmine rake tasks. This is not critical for local development."
}

echo "ℹ️ Redmine setup complete. Default admin login: admin/admin"
echo "⚠️ IMPORTANT: Please update your Claude API key in credentials.yaml"