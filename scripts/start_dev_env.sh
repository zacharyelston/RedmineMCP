#!/bin/bash
# Script to start the development environment for Redmine MCP Extension

# Default configuration
USE_DOCKER=false
PORT=5000
REDMINE_URL="http://localhost:3000"
DEBUG=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --docker)
      USE_DOCKER=true
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --redmine-url)
      REDMINE_URL="$2"
      shift 2
      ;;
    --no-debug)
      DEBUG=false
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Starts the development environment for Redmine MCP Extension."
      echo ""
      echo "Options:"
      echo "  --docker              Use Docker containers (requires Docker and docker-compose)"
      echo "  --port PORT           Port to run the application on (default: 5000)"
      echo "  --redmine-url URL     URL of the Redmine instance (default: http://localhost:3000)"
      echo "  --no-debug            Disable Flask debug mode"
      echo "  --help                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check Python availability for local development
if ! $USE_DOCKER; then
  if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed or not in PATH"
    echo "Please install Python 3 or use --docker option"
    exit 1
  fi
fi

# Check if credentials.yaml exists
if [[ ! -f "credentials.yaml" ]]; then
  echo "⚠️ Warning: credentials.yaml not found"
  
  if [[ -f "credentials.yaml.example" ]]; then
    echo "An example file (credentials.yaml.example) is available."
    read -p "Do you want to create credentials.yaml from the example? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cp credentials.yaml.example credentials.yaml
      echo "✅ Created credentials.yaml from example"
      echo "Please edit the file to add your API keys."
      read -p "Do you want to edit the file now? (y/n) " -n 1 -r
      echo
      
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v nano &> /dev/null; then
          nano credentials.yaml
        elif command -v vim &> /dev/null; then
          vim credentials.yaml
        else
          echo "No editor found. Please edit credentials.yaml manually."
        fi
      fi
    else
      echo "⚠️ Continuing without credentials.yaml"
    fi
  else
    echo "❌ Error: No credentials.yaml or example file found"
    echo "Please create a credentials.yaml file with your Redmine and Claude API keys"
    exit 1
  fi
fi

echo "🚀 Starting Redmine MCP Extension development environment..."

if $USE_DOCKER; then
  # Docker setup
  echo "Starting Docker containers..."
  
  if [[ -f "./start_mcp_dev.sh" ]]; then
    ./start_mcp_dev.sh
  elif [[ -f "./scripts/setup_docker_dev.sh" ]]; then
    # Setup Docker environment if not already set up
    if [[ ! -f "docker-compose.yml" ]]; then
      ./scripts/setup_docker_dev.sh
    fi
    
    # Start containers
    docker-compose up -d
    echo "✅ Docker containers started"
    echo "- Redmine: http://localhost:3000 (admin/admin)"
    echo "- MCP Extension: http://localhost:5000"
  else
    echo "❌ Error: Docker setup scripts not found"
    exit 1
  fi
else
  # Local development setup
  echo "Starting local development server..."
  
  # Check for required packages
  if ! python3 -c "import flask, flask_sqlalchemy" &> /dev/null; then
    echo "Installing required Python packages..."
    pip install -r requirements.txt || pip3 install -r requirements.txt
  fi
  
  # Start the server
  if $DEBUG; then
    echo "Starting in debug mode on port $PORT..."
    FLASK_APP=main.py FLASK_DEBUG=1 REDMINE_URL=$REDMINE_URL python3 main.py
  else
    echo "Starting in production mode on port $PORT..."
    REDMINE_URL=$REDMINE_URL python3 main.py
  fi
fi