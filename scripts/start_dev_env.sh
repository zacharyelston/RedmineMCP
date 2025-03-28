#!/bin/bash

# This script starts the full development environment
# - Redmine container
# - RedmineMCP container
# - Sets up API keys and initial configuration

# Function to check if Docker is running
check_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running. Please start Docker first."
    exit 1
  fi
}

# Function to check if Docker Compose is installed
check_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose not found. Please install Docker Compose."
    exit 1
  fi
}

# Start the environment
start_environment() {
  echo "Starting the development environment..."
  docker compose up -d
  
  # Check if all containers are running
  if [ $(docker compose ps | grep -c "Up") -eq 4 ]; then
    echo "All containers started successfully."
  else
    echo "Some containers failed to start. Please check docker compose logs."
    exit 1
  fi
}

# Setup Redmine API key
setup_redmine() {
  echo "Setting up Redmine API key..."
  ./scripts/setup_redmine.sh
}

# Main script execution
echo "=== Starting RedmineMCP Development Environment ==="
check_docker
check_compose
start_environment
setup_redmine
echo "=== Development environment is now ready ==="
echo "Redmine is available at: http://localhost:3000 (admin/admin)"
echo "RedmineMCP is available at: http://localhost:5000"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"