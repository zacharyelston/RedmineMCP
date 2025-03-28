#!/bin/bash

# Script to start the local development environment with Redmine and MCP Extension

set -e

echo "🚀 Starting Redmine and MCP Extension for local development..."

# Check if credentials.yaml exists, if not create from example
if [ ! -f ./credentials.yaml ]; then
  if [ -f ./credentials.yaml.example ]; then
    echo "⚙️ Creating credentials.yaml from example file..."
    cp ./credentials.yaml.example ./credentials.yaml
    echo "⚠️ WARNING: Please edit credentials.yaml to add your API keys!"
  else
    echo "❌ ERROR: credentials.yaml.example not found. Cannot create default configuration."
    exit 1
  fi
fi

# Build and start the services
echo "🏗️ Building and starting Docker services..."
docker-compose -f docker-compose.local.yml up -d --build

# Wait for services to be ready
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

echo "📋 Development environment setup complete!"
echo "
🔗 Access points:
   - Redmine: http://localhost:3000 (default login: admin/admin)
   - MCP Extension: http://localhost:5000

📝 Next steps:
   1. Log into Redmine and generate an API key (My account > API access key)
   2. Update credentials.yaml with your Redmine URL and API key
   3. Restart the MCP Extension container with: docker restart mcp-extension-local

📕 To view logs:
   - Redmine: docker logs redmine-local -f
   - MCP Extension: docker logs mcp-extension-local -f

🛑 To stop services:
   - docker-compose -f docker-compose.local.yml down
"