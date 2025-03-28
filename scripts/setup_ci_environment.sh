#!/bin/bash
# Script to set up the CI environment for GitHub Actions

set -e

echo "🔧 Setting up CI environment for testing..."

# Determine OS type and install necessary dependencies
if [ -f /etc/os-release ]; then
    . /etc/os-release
    
    echo "📋 Detected OS: $NAME"
    
    # Install required packages based on OS
    case "$ID" in
        debian|ubuntu)
            echo "🔄 Updating package lists..."
            apt-get update -qq
            
            echo "📦 Installing dependencies..."
            apt-get install -y -qq curl wget python3 python3-pip docker.io docker-compose
            ;;
        centos|rhel|fedora)
            echo "🔄 Updating package lists..."
            yum -y update -q
            
            echo "📦 Installing dependencies..."
            yum -y install -q curl wget python3 python3-pip docker docker-compose
            ;;
        alpine)
            echo "🔄 Updating package lists..."
            apk update -q
            
            echo "📦 Installing dependencies..."
            apk add -q curl wget python3 py3-pip docker docker-compose
            ;;
        *)
            echo "⚠️ Unsupported OS: $NAME. Attempting to install dependencies anyway..."
            # Try with apt-get as a fallback
            apt-get update -qq || true
            apt-get install -y -qq curl wget python3 python3-pip docker.io docker-compose || true
            ;;
    esac
else
    echo "⚠️ Could not determine OS type. Attempting to install dependencies..."
    # Try with apt-get as a fallback
    apt-get update -qq || true
    apt-get install -y -qq curl wget python3 python3-pip docker.io docker-compose || true
fi

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install -q pytest pytest-cov requests pyyaml

# Create CI credentials if they don't exist
echo "🔑 Setting up test credentials..."
if [ ! -f credentials.yaml ]; then
    cat > credentials.yaml << EOF
# CI Testing Credentials
redmine:
  url: http://localhost:3000
  api_key: ci_test_api_key

claude:
  api_key: ci_test_claude_api_key  # This is a placeholder, set CLAUDE_API_KEY env var for real tests

# Rate limit (calls per minute) - High for CI
rate_limit: 100
EOF
    echo "✅ Created test credentials"
else
    echo "ℹ️ Using existing credentials.yaml"
fi

# Setup Docker for Redmine testing if Docker is available
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo "🐳 Setting up Docker for Redmine testing..."
    
    # Check if Redmine setup script exists and run it
    if [ -f scripts/setup_redmine_ci.sh ]; then
        chmod +x scripts/setup_redmine_ci.sh
        ./scripts/setup_redmine_ci.sh
    else
        echo "⚠️ scripts/setup_redmine_ci.sh not found. Skipping Redmine container setup."
    fi
else
    echo "⚠️ Docker or docker-compose not available. Skipping Redmine container setup."
fi

echo "✅ CI environment setup complete."
echo "
📋 CI Environment Info:
   - Python version: $(python3 --version)
   - Pip version: $(pip --version)
   - Docker version: $(docker --version 2>/dev/null || echo 'Not available')
   - Docker-compose version: $(docker-compose --version 2>/dev/null || echo 'Not available')
"