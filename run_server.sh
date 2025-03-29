#!/bin/bash
# Run the server on port 5001
echo "Starting Redmine MCP Extension on port 5001..."
gunicorn --bind 0.0.0.0:5001 --reuse-port --reload main:app