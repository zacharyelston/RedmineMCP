#!/bin/bash
# Script to clean up Docker environment for Redmine MCP Extension

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not available in PATH"
    exit 1
fi

echo "⚠️ This script will remove Docker containers, images, and volumes related to Redmine MCP Extension."
echo "Any data stored in the databases will be lost."
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Stopping and removing Docker Compose services..."
if [ -f "docker-compose.yml" ]; then
    docker compose down -v
    echo "✅ Docker Compose services stopped and removed."
else
    echo "ℹ️ No docker-compose.yml file found."
fi

echo "Removing standalone Redmine development container if it exists..."
if docker ps -a --format '{{.Names}}' | grep -q "redmine-dev"; then
    docker stop redmine-dev
    docker rm redmine-dev
    echo "✅ Redmine development container removed."
else
    echo "ℹ️ No redmine-dev container found."
fi

echo "Removing Docker volumes..."
for volume in redmine-data redmine-db-data mcp-db-data redmine-dev-files; do
    if docker volume ls -q | grep -q "$volume"; then
        docker volume rm "$volume"
        echo "✅ Removed volume: $volume"
    else
        echo "ℹ️ Volume not found: $volume"
    fi
done

echo "Checking for unused Docker images..."
# Find Redmine MCP related images
redmine_images=$(docker images | grep -E 'redmine|postgres' | grep -v '<none>' | awk '{print $1":"$2}')
if [ -n "$redmine_images" ]; then
    echo "The following Redmine-related images were found:"
    echo "$redmine_images"
    read -p "Do you want to remove these images? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for img in $redmine_images; do
            docker rmi "$img"
            echo "✅ Removed image: $img"
        done
    else
        echo "Skipping image removal."
    fi
else
    echo "ℹ️ No Redmine-related images found."
fi

# Final cleanup
echo "Running Docker system prune to remove any other unused resources..."
read -p "Do you want to run docker system prune? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune -f
    echo "✅ Docker system pruned."
else
    echo "Skipping system prune."
fi

echo ""
echo "🎉 Cleanup complete! The Docker environment has been reset."
echo "To set up the environment again, run: ./scripts/setup_docker_dev.sh"