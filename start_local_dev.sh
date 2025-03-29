#!/bin/bash

# Script to start the local development environment with Redmine and MCP Extension

set -e

echo "🚀 Starting Redmine and MCP Extension for local development..."

# Check if we have the setup script
if [ -f ./scripts/setup_redmine.sh ]; then
  # Run the setup script which will handle Docker, credentials, and API key setup
  echo "⚙️ Running Redmine setup script..."
  chmod +x ./scripts/setup_redmine.sh
  ./scripts/setup_redmine.sh
else
  # Fall back to the old method if setup script is not available
  echo "⚠️ setup_redmine.sh not found, using basic setup..."
  
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
  # First remove any existing containers to avoid the 'ContainerConfig' KeyError on ARM64
  docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
  docker rm -f redmine-local 2>/dev/null || true
  
  # Start with --force-recreate to avoid volume issues on ARM64
  docker-compose -f docker-compose.local.yml up -d --build --force-recreate

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
fi

echo "📋 Development environment setup complete!"
echo "
🔗 Access points:
   - Redmine: http://localhost:3000 (default login: admin/admin)
   - MCP Extension: http://localhost:9000

📝 Next steps:
   1. Add your LLM provider API key to credentials.yaml:
      - Add 'claude_api_key' to credentials.yaml (Claude is the only supported LLM)
      (if using automated setup, Redmine API key is already set)
   2. Start the MCP Extension: flask run --host=0.0.0.0 --port=9000
   3. Or use the workflow: gunicorn --bind 0.0.0.0:9000 --reuse-port --reload main:app

📕 To view logs:
   - Redmine: docker logs redmine-local -f
   - MCP Extension: tail -f app.log (if you've enabled logging)

📡 Testing the APIs:
   - Redmine API: python scripts/test_redmine_api.py --verbose
   - LLM API:
     - Claude API: python scripts/test_claude_api.py --verbose
   - MCP Integration: python scripts/test_mcp_integration.py --project-id=test

🛑 To stop services:
   - docker-compose -f docker-compose.local.yml down
"