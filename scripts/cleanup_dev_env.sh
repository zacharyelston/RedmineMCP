#!/bin/bash

# This script cleans up the development environment
# Stops containers and removes volumes for a fresh start

echo "=== Cleaning up RedmineMCP Development Environment ==="

read -p "This will stop all containers and remove their data. Are you sure? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Stopping all containers..."
  docker compose down
  
  echo "Removing volumes..."
  docker volume rm $(docker volume ls -q | grep redmine) 2>/dev/null || true
  
  echo "Removing credentials file..."
  rm -f credentials.yaml
  
  echo "Cleanup complete. You can start fresh with ./scripts/start_dev_env.sh"
else
  echo "Cleanup cancelled."
fi