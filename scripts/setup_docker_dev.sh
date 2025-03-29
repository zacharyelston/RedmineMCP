#!/bin/bash
# Setup Docker development environment for the Redmine MCP Extension
# This script configures and starts a complete Docker-based development environment
# with both Redmine and the MCP Extension

set -e  # Exit on error

echo "🚀 Setting up Docker development environment for Redmine MCP Extension..."

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker and Docker Compose are required but not found."
    echo "   Please install Docker Desktop or Docker Engine with Docker Compose."
    exit 1
fi

# Create the docker-compose.dev.yml file if it doesn't exist
if [ ! -f docker-compose.dev.yml ]; then
    echo "📝 Creating docker-compose.dev.yml file..."
    cat > docker-compose.dev.yml << 'EOF'
version: '3'

services:
  db:
    image: mariadb:10.5
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=redminedbpass
      - MYSQL_DATABASE=redmine
      - MYSQL_USER=redmine
      - MYSQL_PASSWORD=redmine
    volumes:
      - redmine-db:/var/lib/mysql
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

  redmine:
    image: redmine:5.0
    restart: always
    depends_on:
      - db
    ports:
      - "3000:3000"
    environment:
      - REDMINE_DB_MYSQL=db
      - REDMINE_DB_DATABASE=redmine
      - REDMINE_DB_USERNAME=redmine
      - REDMINE_DB_PASSWORD=redmine
      - REDMINE_SECRET_KEY_BASE=supersecretkeysupersecretsupersecretsupersecretsupersecretsupersecretsupersecret
    volumes:
      - redmine-files:/usr/src/redmine/files
      - redmine-plugins:/usr/src/redmine/plugins
    
  mcp-extension:
    build: .
    restart: always
    depends_on:
      - redmine
    ports:
      - "5000:5000"
    environment:
      - REDMINE_URL=http://redmine:3000
      - REDMINE_API_KEY=automaticallyconfigured
      - CLAUDE_API_KEY=${CLAUDE_API_KEY:-}
      - OPENAI_API_KEY=${OPENAI_API_KEY:-}
      - LLM_PROVIDER=${LLM_PROVIDER:-claude}
      - FLASK_ENV=development
      - DATABASE_URL=sqlite:///mcp_extension.db
    volumes:
      - .:/app
    command: gunicorn --bind 0.0.0.0:5000 --reload main:app

volumes:
  redmine-db:
  redmine-files:
  redmine-plugins:
EOF
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# Environment variables for the Redmine MCP Extension
# Fill in your API keys below (leave empty if not used)

# LLM Provider - only 'claude' is supported
LLM_PROVIDER=claude

# API Key for Claude
CLAUDE_API_KEY=

# Redmine configuration is handled automatically by the Docker setup
EOF
    
    echo "⚠️ Please edit the .env file to add your API keys."
fi

# Create start_mcp_dev.sh script if it doesn't exist
if [ ! -f start_mcp_dev.sh ]; then
    echo "📝 Creating start_mcp_dev.sh script..."
    cat > start_mcp_dev.sh << 'EOF'
#!/bin/bash
# Start the Docker development environment for Redmine MCP Extension

echo "🚀 Starting Redmine MCP Extension development environment..."

# First remove any existing containers to avoid the 'ContainerConfig' KeyError on ARM64
docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
docker rm -f redmine db mcp-extension 2>/dev/null || true

# Start with --force-recreate to avoid volume issues on ARM64
docker-compose -f docker-compose.dev.yml up -d --force-recreate

echo "⏳ Waiting for Redmine to start (this may take a minute)..."
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
    echo "❌ Timed out waiting for Redmine to start. Check container logs with: docker-compose -f docker-compose.dev.yml logs redmine"
    exit 1
fi

echo "✅ Development environment is running!"
echo "📋 Access points:"
echo "   - Redmine: http://localhost:3000 (admin/admin)"
echo "   - MCP Extension: http://localhost:5000"
echo ""
echo "📦 To view logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "🛑 To stop: docker-compose -f docker-compose.dev.yml down"
EOF
    
    chmod +x start_mcp_dev.sh
fi

# Create a sample dev content script
if [ ! -f scripts/create_dev_content.sh ]; then
    echo "📝 Creating scripts/create_dev_content.sh script..."
    mkdir -p scripts
    cat > scripts/create_dev_content.sh << 'EOF'
#!/bin/bash
# Create sample content in Redmine for development purposes

echo "🏗️ Creating sample development content in Redmine..."

# Wait for Redmine to be up
attempt=0
max_attempts=10
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:3000 > /dev/null; then
        break
    fi
    attempt=$((attempt+1))
    echo "⏳ Waiting for Redmine... ($attempt/$max_attempts)"
    sleep 2
done

# Create a test project
echo "📋 Creating sample project..."
curl -s -X POST http://localhost:3000/projects.json \
     -H "Content-Type: application/json" \
     -H "X-Redmine-API-Key: automaticallyconfigured" \
     -d '{"project":{"name":"MCP Test Project","identifier":"mcp-test","description":"A test project for MCP extension development"}}' \
     > /dev/null

# Create some sample issues
echo "📋 Creating sample issues..."
curl -s -X POST http://localhost:3000/issues.json \
     -H "Content-Type: application/json" \
     -H "X-Redmine-API-Key: automaticallyconfigured" \
     -d '{"issue":{"project_id":"mcp-test","subject":"Test Issue 1","description":"This is a test issue for development"}}' \
     > /dev/null

curl -s -X POST http://localhost:3000/issues.json \
     -H "Content-Type: application/json" \
     -H "X-Redmine-API-Key: automaticallyconfigured" \
     -d '{"issue":{"project_id":"mcp-test","subject":"Test Issue 2","description":"This is another test issue with different content for testing LLM analysis"}}' \
     > /dev/null

echo "✅ Sample content created successfully!"
EOF
    
    chmod +x scripts/create_dev_content.sh
fi

echo "🔧 Setting execute permissions..."
chmod +x start_mcp_dev.sh
chmod +x scripts/create_dev_content.sh

echo "✅ Docker development environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file to add your API keys"
echo "2. Start the environment with: ./start_mcp_dev.sh"
echo "3. Optional: Create sample content with: ./scripts/create_dev_content.sh"
echo ""
echo "ℹ️ Default Redmine login: admin/admin"