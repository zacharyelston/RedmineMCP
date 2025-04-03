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
echo ""
echo "SECURITY NOTICE:"
echo "For security best practices, do not hardcode your Redmine API key in the Dockerfile."
echo "Instead, pass it securely at runtime through environment variables in the Claude Desktop MCP configuration."
echo "Example:"
echo "  \"environment\": {"
echo "    \"REDMINE_API_KEY\": \"your-redmine-api-key\","
echo "    \"REDMINE_URL\": \"https://your-redmine-instance.com\","
echo "    \"LLM_PROVIDER\": \"claude\","
echo "    \"RATE_LIMIT\": \"30\""
echo "  }"