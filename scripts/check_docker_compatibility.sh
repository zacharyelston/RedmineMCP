#!/bin/bash
# Script to check Docker compatibility and debug common issues

set -e

# Print system information
echo "🔍 System Information"
echo "===================="
uname -a

# Check Docker version
echo ""
echo "🐳 Docker Information"
echo "===================="
if command -v docker &> /dev/null; then
    docker --version
    docker info 2>/dev/null | grep -E "Architecture|Operating System" || echo "Could not get detailed Docker info"
else
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

# Check Docker Compose version
echo ""
echo "🔄 Docker Compose Information"
echo "==========================="
if command -v docker-compose &> /dev/null; then
    docker-compose --version
else
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

# Check if docker is running
echo ""
echo "🏃 Docker Status"
echo "==============="
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running."
else
    echo "❌ Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Check for ARM64 compatibility issues
echo ""
echo "🖥️ Architecture Check"
echo "==================="
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    echo "🔍 Detected ARM64 architecture (Apple Silicon / ARM64)"
    echo "ℹ️ Some compatibility fixes will be applied for ARM64 systems."
    IS_ARM64=true
else
    echo "🔍 Detected x86_64/AMD64 architecture"
    echo "ℹ️ Standard Docker configuration should work without issues."
    IS_ARM64=false
fi

# Display Docker images
echo ""
echo "📦 Docker Images"
echo "==============="
docker images | head -20

# Display running containers
echo ""
echo "🏭 Running Containers"
echo "==================="
docker ps

# Check for known issues
echo ""
echo "🔍 Checking for known issues..."
echo ""

# Check if redmine-local is running
if docker ps | grep -q redmine-local; then
    echo "✅ Redmine container is running."
    
    # Test Redmine connectivity
    echo "ℹ️ Testing Redmine HTTP connection..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000; then
        echo "✅ Redmine is accessible via HTTP."
    else
        echo "⚠️ Redmine is running but HTTP connection failed."
        echo "ℹ️ This could be due to Redmine still starting up."
    fi
else
    echo "⚠️ Redmine container is not running."
    
    # Check if it exists but is stopped
    if docker ps -a | grep -q redmine-local; then
        echo "ℹ️ Redmine container exists but is not running."
        echo "📋 Last logs from Redmine container:"
        docker logs --tail 20 redmine-local 2>/dev/null || echo "Could not get logs."
    else
        echo "ℹ️ No Redmine container found."
    fi
fi

# Check if mcp-extension-local is running
if docker ps | grep -q mcp-extension-local; then
    echo "✅ MCP Extension container is running."
    
    # Test MCP Extension connectivity
    echo "ℹ️ Testing MCP Extension HTTP connection..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000; then
        echo "✅ MCP Extension is accessible via HTTP."
    else
        echo "⚠️ MCP Extension is running but HTTP connection failed."
    fi
else
    echo "⚠️ MCP Extension container is not running."
    
    # Check if it exists but is stopped
    if docker ps -a | grep -q mcp-extension-local; then
        echo "ℹ️ MCP Extension container exists but is not running."
        echo "📋 Last logs from MCP Extension container:"
        docker logs --tail 20 mcp-extension-local 2>/dev/null || echo "Could not get logs."
    else
        echo "ℹ️ No MCP Extension container found."
    fi
fi

# Check docker-compose.local.yml
echo ""
echo "📄 Checking docker-compose.local.yml"
echo "================================="
if [ -f ./docker-compose.local.yml ]; then
    echo "✅ docker-compose.local.yml exists."
    
    # Check for ARM64 compatibility issues in the file
    if [ "$IS_ARM64" = true ]; then
        echo "ℹ️ Checking for ARM64 compatibility issues in docker-compose.local.yml..."
        
        # Look for potentially problematic settings
        if grep -q "service_healthy" docker-compose.local.yml; then
            echo "⚠️ Found 'service_healthy' condition which might cause issues on ARM64."
            echo "ℹ️ Consider replacing with simple 'depends_on' without conditions."
        else
            echo "✅ No problematic 'service_healthy' condition found."
        fi
    fi
else
    echo "❌ docker-compose.local.yml not found in the current directory."
fi

# Check credentials.yaml
echo ""
echo "📄 Checking credentials.yaml"
echo "========================="
if [ -f ./credentials.yaml ]; then
    echo "✅ credentials.yaml exists."
    
    # Check for test values
    if grep -q "test-redmine-instance" credentials.yaml; then
        echo "ℹ️ credentials.yaml contains test Redmine URL."
    fi
else
    echo "❌ credentials.yaml not found in the current directory."
    
    if [ -f ./credentials.yaml.example ]; then
        echo "ℹ️ credentials.yaml.example exists. Run setup_redmine.sh to create credentials.yaml."
    fi
fi

echo ""
echo "✅ Docker compatibility check complete."
echo "ℹ️ Use this information to diagnose any issues with Docker setup."