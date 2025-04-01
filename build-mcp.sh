#!/bin/bash
set -e

# Set the Docker image name and tag
IMAGE_NAME="redmine-mcp-extension"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Build the Docker image for Redmine MCP Extension
echo "Building Redmine MCP Extension Docker image..."
docker build -t ${FULL_IMAGE_NAME} .

echo "Build complete! Image name: ${FULL_IMAGE_NAME}"
echo "To add this MCP extension to Claude Desktop, update your MCP configuration file."
echo "Make sure to use the fully qualified image name in your MCP configuration."