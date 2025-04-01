#!/bin/bash
# Run the server on port 9000
echo "Starting Redmine MCP Extension on port 9000..."
gunicorn --bind 0.0.0.0:9000 --reuse-port --reload main:app