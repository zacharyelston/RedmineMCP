#!/bin/bash
# Script to set up Redmine in CI environment (GitHub Actions)

set -e

# This script is meant to be run in a CI environment where Docker containers
# are available but with ephemeral volumes. It sets up a Redmine instance
# for testing purposes with predictable configuration.

REDMINE_URL="http://localhost:3000"
REDMINE_API_KEY="ci_test_api_key"
CLAUDE_API_KEY="${CLAUDE_API_KEY:-ci_test_claude_key}"

echo "🚀 Setting up Redmine for CI testing..."

# Create credentials file for CI
echo "⚙️ Creating credentials.yaml for CI environment..."
cat > ./credentials.yaml << EOF
# Redmine MCP Extension CI Credentials
redmine:
  url: ${REDMINE_URL}
  api_key: ${REDMINE_API_KEY}

claude:
  api_key: ${CLAUDE_API_KEY}

# Rate limit (calls per minute) - High for CI to avoid throttling
rate_limit: 100
EOF

echo "✅ Created credentials.yaml for CI"

# Start Docker containers in detached mode
echo "🏗️ Starting Redmine container for CI..."
# Use simplified docker-compose config for CI
cat > ./docker-compose.ci.yml << EOF
version: '3'
services:
  redmine:
    image: redmine:5.0
    container_name: redmine-ci
    ports:
      - "3000:3000"
    environment:
      - REDMINE_SECRET_KEY_BASE=citest
      - REDMINE_DB_MYSQL=redmine-db
      - REDMINE_DB_PASSWORD=redmine
      - REDMINE_DB_USERNAME=redmine
      - REDMINE_DB_DATABASE=redmine
      - REDMINE_PLUGINS_MIGRATE=true

  redmine-db:
    image: mariadb:10.5
    container_name: redmine-db-ci
    environment:
      - MYSQL_ROOT_PASSWORD=redmine
      - MYSQL_DATABASE=redmine
      - MYSQL_USER=redmine
      - MYSQL_PASSWORD=redmine
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
EOF

docker-compose -f docker-compose.ci.yml up -d

# Wait for Redmine to start with shorter timeout for CI
echo "⏳ Waiting for Redmine to be ready..."
attempt=0
max_attempts=20  # Shorter timeout for CI
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Redmine is up and running!"
        break
    fi
    attempt=$((attempt+1))
    echo "⏳ Waiting for Redmine... ($attempt/$max_attempts)"
    sleep 3  # Shorter sleep for CI
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Timed out waiting for Redmine to start in CI environment."
    docker logs redmine-ci
    exit 1
fi

# Set up API access token in Redmine
# In CI we can hard-code this with a known value
echo "⚙️ Configuring Redmine API access for CI..."
docker exec redmine-ci bash -c 'bundle exec rake redmine:plugins:migrate RAILS_ENV=production && bundle exec rake generate_secret_token' || {
    echo "⚠️ Warning: Could not run Redmine rake tasks. API access might not work."
}

echo "✅ Redmine CI setup complete"