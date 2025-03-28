#!/bin/bash
# Setup Docker development environment for Redmine MCP Extension

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not available in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker compose &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed or not available in PATH"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "🚀 Setting up Docker development environment for Redmine MCP Extension..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Redmine settings
REDMINE_PORT=3000
REDMINE_DB_POSTGRES=true
REDMINE_DB_PASSWORD=redmine_db_password
REDMINE_SECRET_KEY_BASE=$(openssl rand -hex 32)

# MCP Extension settings
MCP_PORT=5000
CLAUDE_API_KEY=your_claude_api_key_here

# Database settings for MCP
POSTGRES_PASSWORD=postgres_password
POSTGRES_USER=postgres
POSTGRES_DB=redmine_mcp
EOF
    echo "✅ Created .env file. Please edit it to set your Claude API key."
else
    echo "ℹ️ .env file already exists. Skipping creation."
fi

# Create or update docker-compose.yml file
echo "Creating docker-compose.yml file..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  # Redmine instance
  redmine:
    image: redmine:5.0
    depends_on:
      - redmine-db
    ports:
      - "\${REDMINE_PORT}:3000"
    environment:
      REDMINE_DB_POSTGRES: \${REDMINE_DB_POSTGRES}
      REDMINE_DB_USERNAME: postgres
      REDMINE_DB_PASSWORD: \${REDMINE_DB_PASSWORD}
      REDMINE_DB_DATABASE: redmine
      REDMINE_DB_HOST: redmine-db
      REDMINE_SECRET_KEY_BASE: \${REDMINE_SECRET_KEY_BASE}
    volumes:
      - redmine-data:/usr/src/redmine/files
    restart: unless-stopped

  # Database for Redmine
  redmine-db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: \${REDMINE_DB_PASSWORD}
      POSTGRES_USER: postgres
      POSTGRES_DB: redmine
    volumes:
      - redmine-db-data:/var/lib/postgresql/data
    restart: unless-stopped

  # MCP Extension
  redmine-mcp:
    build: .
    depends_on:
      - mcp-db
      - redmine
    ports:
      - "\${MCP_PORT}:5000"
    environment:
      DATABASE_URL: postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@mcp-db/\${POSTGRES_DB}
      CLAUDE_API_KEY: \${CLAUDE_API_KEY}
      REDMINE_URL: http://redmine:3000
      SESSION_SECRET: \${REDMINE_SECRET_KEY_BASE}
    volumes:
      - .:/app
    restart: unless-stopped

  # Database for MCP Extension
  mcp-db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_DB: \${POSTGRES_DB}
    volumes:
      - mcp-db-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  redmine-data:
  redmine-db-data:
  mcp-db-data:
EOF
echo "✅ Created docker-compose.yml file."

# Create Dockerfile if it doesn't exist
if [ ! -f Dockerfile ]; then
    echo "Creating Dockerfile..."
    cat > Dockerfile << EOF
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DATABASE_URL=postgresql://postgres:postgres_password@mcp-db/redmine_mcp

# Expose port
EXPOSE 5000

# Start the application
CMD ["python", "main.py"]
EOF
    echo "✅ Created Dockerfile."
else
    echo "ℹ️ Dockerfile already exists. Skipping creation."
fi

# Create requirements.txt if it doesn't exist
if [ ! -f requirements.txt ]; then
    echo "Creating requirements.txt..."
    cat > requirements.txt << EOF
flask==2.3.3
flask-sqlalchemy==3.1.1
pyyaml==6.0.1
requests==2.31.0
gunicorn==21.2.0
psycopg2-binary==2.9.9
pytest==7.4.2
responses==0.23.3
EOF
    echo "✅ Created requirements.txt."
else
    echo "ℹ️ requirements.txt already exists. Skipping creation."
fi

# Create start script for easier container startup
echo "Creating start_mcp_dev.sh script..."
cat > start_mcp_dev.sh << EOF
#!/bin/bash
# Start the Redmine MCP Extension in development mode

echo "Starting Redmine MCP Extension..."
docker compose up -d

echo "✅ Services started! You can access them at:"
echo "- Redmine: http://localhost:\${REDMINE_PORT:-3000} (admin/admin)"
echo "- MCP Extension: http://localhost:\${MCP_PORT:-5000}"
EOF
chmod +x start_mcp_dev.sh
echo "✅ Created start_mcp_dev.sh script."

echo ""
echo "🎉 Setup complete! Follow these steps to start development:"
echo ""
echo "1. Edit .env file to set your Claude API key"
echo "2. Start the environment by running:"
echo "   ./start_mcp_dev.sh"
echo ""
echo "Access the applications at:"
echo "- Redmine: http://localhost:3000 (default login: admin/admin)"
echo "- MCP Extension: http://localhost:5000"
echo ""
echo "After first login to Redmine, generate an API key in your account settings"
echo "and update the configuration in the MCP Extension web interface."