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
echo "⚠️ This may take a while on first run..."

# First make sure any existing containers are stopped and removed
echo "🧹 Cleaning up any existing containers..."
docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
docker rm -f redmine-local mcp-extension-local 2>/dev/null || true
docker volume rm redmine-local-files 2>/dev/null || true

# Ensure docker images are up to date
echo "🔄 Building fresh images..."
docker-compose -f docker-compose.local.yml build --no-cache

# Start with --force-recreate to avoid volume issues on ARM64
echo "🚀 Starting services..."
docker-compose -f docker-compose.local.yml up -d --force-recreate

# Check if MCP Extension started
echo "⏳ Checking if MCP Extension is running..."
mcp_attempt=0
mcp_max_attempts=10
while [ $mcp_attempt -lt $mcp_max_attempts ]; do
    if docker ps | grep -q mcp-extension-local; then
        echo "✅ MCP Extension container is running!"
        break
    fi
    mcp_attempt=$((mcp_attempt+1))
    echo "⏳ Waiting for MCP Extension... ($mcp_attempt/$mcp_max_attempts)"
    sleep 2
done

if [ $mcp_attempt -eq $mcp_max_attempts ]; then
    echo "❌ MCP Extension container failed to start. Check logs with: docker logs mcp-extension-local"
    # Don't exit, we still want to check Redmine
fi

# Wait for Redmine to start (but continue even if it fails)
echo "⏳ Waiting for Redmine to be ready (this may take a minute)..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Redmine is up and running!"
        redmine_running=true
        break
    fi
    attempt=$((attempt+1))
    echo "⏳ Waiting for Redmine... ($attempt/$max_attempts)"
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "⚠️ Redmine may not be ready yet. This is not critical for MCP extension to function."
    echo "ℹ️ You can check Redmine logs with: docker logs redmine-local"
    redmine_running=false
fi

# Only configure Redmine if it's running
if [ "$redmine_running" = true ]; then
    echo "⚙️ Configuring Redmine with API access..."
    docker exec redmine-local bash -c 'bundle exec rake redmine:plugins:migrate RAILS_ENV=production && bundle exec rake generate_secret_token' || {
        echo "⚠️ Warning: Could not run Redmine rake tasks. This is not critical for local development."
    }
    echo "ℹ️ Redmine setup complete. Default admin login: admin/admin"
else
    echo "ℹ️ Skipping Redmine configuration as Redmine is not yet available."
    echo "ℹ️ You can manually configure Redmine later when it becomes available."
fi

echo "✅ MCP Extension should be accessible at http://localhost:9000"
echo "⚠️ IMPORTANT: Please update your API keys in credentials.yaml"

# Print status summary
echo ""
echo "🚀 Setup Summary:"
echo "===================="
if [ "$redmine_running" = true ]; then
    echo "Redmine: ✅ Running at http://localhost:3000"
else
    echo "Redmine: ⚠️ Not yet available (http://localhost:3000)"
fi

if docker ps | grep -q mcp-extension-local; then
    echo "MCP Extension: ✅ Running at http://localhost:9000"
else
    echo "MCP Extension: ❌ Not running"
fi

echo ""
echo "You can check container logs with:"
echo "  docker logs redmine-local        # For Redmine logs"
echo "  docker logs mcp-extension-local  # For MCP Extension logs"