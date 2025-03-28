#!/bin/bash
# Script to clean up the development environment for Redmine MCP Extension

echo "⚠️ This script will remove temporary and development files."
echo "Any unsaved changes may be lost."
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "🧹 Cleaning up development environment..."

# Remove Python cache files
echo "Removing Python cache files..."
find . -type d -name "__pycache__" -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete
find . -type f -name ".coverage" -delete
find . -type d -name ".pytest_cache" -exec rm -rf {} +
find . -type d -name ".cache" -exec rm -rf {} +
echo "✅ Removed Python cache files"

# Remove temporary files
echo "Removing temporary files..."
find . -type f -name "*.log" -delete
find . -type f -name "*.bak" -delete
find . -type f -name "*.swp" -delete
find . -type f -name "*.swo" -delete
find . -type f -name "*~" -delete
find . -type f -name ".DS_Store" -delete
echo "✅ Removed temporary files"

# Remove database files if they exist
echo "Checking for SQLite database files..."
find . -type f -name "*.db" | while read -r db_file; do
    echo "  Found database: $db_file"
    read -p "  Do you want to remove this database? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$db_file"
        echo "  ✅ Removed database: $db_file"
    else
        echo "  ℹ️ Skipped database: $db_file"
    fi
done

# Clean up Docker containers (if Docker is installed)
if command -v docker &> /dev/null; then
    echo "Checking for running Docker containers..."
    if docker ps -a --format '{{.Names}}' | grep -q "redmine\|mcp"; then
        echo "Found Redmine/MCP Docker containers."
        read -p "Do you want to clean up Docker containers as well? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./scripts/cleanup_docker_env.sh
        else
            echo "ℹ️ Skipping Docker cleanup"
        fi
    else
        echo "ℹ️ No Redmine/MCP Docker containers found"
    fi
else
    echo "ℹ️ Docker not installed, skipping container cleanup"
fi

# Final message
echo ""
echo "🎉 Development environment cleaned up successfully!"
echo "You can restart the environment using the appropriate scripts:"
echo "- For Docker: ./scripts/setup_docker_dev.sh"
echo "- For local development: python main.py"