FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY . /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r docker-requirements.txt

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# Create a config directory
RUN mkdir -p /app/config

# Create entrypoint script
RUN echo '#!/bin/bash\n\
# Generate credentials.yaml from environment variables\n\
echo "redmine_url: ${REDMINE_URL:-\"http://localhost:3000\"}"\n > /app/credentials.yaml\n\
echo "redmine_api_key: ${REDMINE_API_KEY:-\"\"}"\n >> /app/credentials.yaml\n\
echo "llm_provider: \"claude-desktop\""\n >> /app/credentials.yaml\n\
echo "mcp_url: \"http://localhost:9000\""\n >> /app/credentials.yaml\n\
echo "rate_limit_per_minute: 60"\n >> /app/credentials.yaml\n\
\n\
# Start the application\n\
exec gunicorn --bind 0.0.0.0:9000 --reuse-port main:app\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Expose the MCP service port
EXPOSE 9000

# Run the application with the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]