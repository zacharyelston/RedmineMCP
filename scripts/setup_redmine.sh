#!/bin/bash
# Script to set up a local Redmine instance for development

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "🚀 Setting up a local Redmine instance for development..."

# Create a standalone Redmine Docker container for quick testing
docker run --name redmine-dev \
  -d \
  -p 3000:3000 \
  -e REDMINE_DB_SQLITE=/redmine/db/sqlite/redmine.db \
  -v redmine-dev-files:/usr/src/redmine/files \
  redmine:5.0

# Wait for Redmine to start
echo "⏳ Waiting for Redmine to start (this may take up to 60 seconds)..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        echo "✅ Redmine is ready!"
        break
    fi
    sleep 2
    echo -n "."
    if [ $i -eq 30 ]; then
        echo ""
        echo "❌ Redmine did not start successfully within the timeout period."
        echo "Check Docker logs with: docker logs redmine-dev"
        exit 1
    fi
done

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Redmine is now available at: http://localhost:3000"
echo "Default admin credentials: admin/admin"
echo ""
echo "After first login:"
echo "1. Go to 'My account' (top right) to generate an API key"
echo "2. Update the 'credentials.yaml' file with your Redmine URL and API key"
echo ""
echo "To stop the Redmine container, run:"
echo "docker stop redmine-dev"
echo ""
echo "To start it again later, run:"
echo "docker start redmine-dev"
echo ""
echo "To view logs, run:"
echo "docker logs redmine-dev"