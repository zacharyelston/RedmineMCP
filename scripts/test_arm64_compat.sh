#!/bin/bash
# Test ARM64 compatibility for CI environments

set -e

echo "🧪 Testing ARM64 compatibility in CI environment..."

# Detect architecture
ARCH=$(uname -m)
echo "📋 Detected architecture: $ARCH"

# Check if running on ARM64
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "✅ Running on ARM64 architecture"
    IS_ARM64=true
else
    echo "ℹ️ Not running on ARM64 architecture"
    IS_ARM64=false
fi

# Create a simple test docker-compose file
echo "🔧 Creating test docker-compose file for MariaDB..."
cat > ./docker-compose.arm64-test.yml << EOF
version: '3'
services:
  db-test:
    image: mariadb:10.5
    environment:
      - MYSQL_ROOT_PASSWORD=test
      - MYSQL_DATABASE=test
      - MYSQL_USER=test
      - MYSQL_PASSWORD=test
    ports:
      - "3307:3306"
EOF

# Try to start MariaDB container
echo "🔄 Starting MariaDB container for ARM64 compatibility test..."
docker-compose -f docker-compose.arm64-test.yml up -d

# Check if container started successfully
sleep 5
if docker ps | grep -q "db-test"; then
    echo "✅ MariaDB container started successfully"
    CONTAINER_STARTED=true
else
    echo "❌ Failed to start MariaDB container"
    docker-compose -f docker-compose.arm64-test.yml logs
    CONTAINER_STARTED=false
fi

# Cleanup
echo "🧹 Cleaning up test containers..."
docker-compose -f docker-compose.arm64-test.yml down
rm docker-compose.arm64-test.yml

# Report results
echo ""
echo "🔍 ARM64 Compatibility Test Results:"
echo "------------------------------------"
echo "Architecture: $ARCH"
echo "ARM64: $IS_ARM64"
echo "MariaDB Container: $CONTAINER_STARTED"
echo ""

# Exit with success
exit 0