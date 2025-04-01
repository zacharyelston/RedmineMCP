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

# Set default configuration environment variables
ENV REDMINE_URL="http://localhost:3000"
# API key should be passed at runtime as a secret
# Not predefined in the image
ENV LLM_PROVIDER="claude-desktop"
ENV MCP_URL="http://localhost:9000"
ENV RATE_LIMIT=60

# Create config and logs directories
RUN mkdir -p /app/config /app/logs

# Create entrypoint script
RUN echo '#!/bin/bash\n\
\n\
# Create logs directory if it doesn'"'"'t exist\n\
mkdir -p /app/logs\n\
\n\
# Output environment configuration for debugging\n\
echo "Starting with the following configuration:"\n\
echo "REDMINE_URL: ${REDMINE_URL}"\n\
echo "REDMINE_API_KEY: [REDACTED]"\n\
echo "LLM_PROVIDER: ${LLM_PROVIDER}"\n\
echo "MCP_URL: ${MCP_URL}"\n\
echo "RATE_LIMIT: ${RATE_LIMIT}"\n\
\n\
# Start the application\n\
exec gunicorn --bind 0.0.0.0:9000 --reuse-port --access-logfile - --error-logfile - main:app\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Expose the MCP service port
EXPOSE 9000

# Run the application with the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]