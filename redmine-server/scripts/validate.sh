#!/bin/bash
# Redmine Database Validation Script

# Set color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=== Redmine Database Validation ===${NC}"
echo -e "${YELLOW}=================================${NC}"
echo ""

# Check if docker is running
echo -e "Checking Docker status..."
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Docker is not running!${NC}"
  echo -e "${YELLOW}Please start Docker and try again.${NC}"
  exit 1
else
  echo -e "${GREEN}Docker is running.${NC}"
fi

# Check if the containers are running
echo -e "\nChecking container status..."
if ! docker ps | grep -q "redmine-postgres"; then
  echo -e "${RED}PostgreSQL container is not running!${NC}"
  echo -e "${YELLOW}Run docker-compose up -d to start the containers.${NC}"
  exit 1
else
  echo -e "${GREEN}PostgreSQL container is running.${NC}"
fi

if ! docker ps | grep -q "redmine-app"; then
  echo -e "${RED}Redmine container is not running!${NC}"
  echo -e "${YELLOW}Run docker-compose up -d to start the containers.${NC}"
  exit 1
else
  echo -e "${GREEN}Redmine container is running.${NC}"
fi

# Check PostgreSQL connection
echo -e "\nChecking PostgreSQL connection..."
if ! docker exec redmine-postgres pg_isready -U redmine >/dev/null 2>&1; then
  echo -e "${RED}Cannot connect to PostgreSQL!${NC}"
  exit 1
else
  echo -e "${GREEN}PostgreSQL connection successful.${NC}"
fi

# Check if Flyway migrations applied successfully
echo -e "\nChecking Flyway migration status..."
MIGRATION_COUNT=$(docker exec redmine-postgres psql -U redmine -d redmine -t -c "SELECT COUNT(*) FROM flyway_schema_history WHERE success = true;")

if [ -z "$MIGRATION_COUNT" ] || [ "$MIGRATION_COUNT" -eq "0" ]; then
  echo -e "${RED}No successful Flyway migrations found!${NC}"
  echo -e "${YELLOW}Run docker-compose run --rm flyway migrate to apply migrations.${NC}"
  exit 1
else
  echo -e "${GREEN}$MIGRATION_COUNT Flyway migrations applied successfully.${NC}"
fi

# Check if Redmine is responding
echo -e "\nChecking Redmine API access..."
if ! curl -s http://localhost:3000 >/dev/null; then
  echo -e "${RED}Redmine is not responding!${NC}"
  exit 1
else
  echo -e "${GREEN}Redmine is responding.${NC}"
fi

# Check API keys
echo -e "\nValidating API keys..."
# Test admin API key
ADMIN_RESP=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Redmine-API-Key: 7a4ed5c91b405d30fda60909dbc86c2651c38217" http://localhost:3000/users/current.json)
if [ "$ADMIN_RESP" -eq "200" ]; then
  echo -e "${GREEN}Admin API key is valid.${NC}"
else
  echo -e "${RED}Admin API key validation failed with status $ADMIN_RESP!${NC}"
fi

# Test user API key
USER_RESP=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Redmine-API-Key: 3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0" http://localhost:3000/users/current.json)
if [ "$USER_RESP" -eq "200" ]; then
  echo -e "${GREEN}Test user API key is valid.${NC}"
else
  echo -e "${RED}Test user API key validation failed with status $USER_RESP!${NC}"
fi

# Check projects count
echo -e "\nChecking projects..."
PROJECTS_COUNT=$(docker exec redmine-postgres psql -U redmine -d redmine -t -c "SELECT COUNT(*) FROM projects;")
echo -e "${GREEN}$PROJECTS_COUNT projects found.${NC}"

# Check users count
echo -e "\nChecking users..."
USERS_COUNT=$(docker exec redmine-postgres psql -U redmine -d redmine -t -c "SELECT COUNT(*) FROM users WHERE type='User';")
echo -e "${GREEN}$USERS_COUNT users found.${NC}"

# Check issues count
echo -e "\nChecking issues..."
ISSUES_COUNT=$(docker exec redmine-postgres psql -U redmine -d redmine -t -c "SELECT COUNT(*) FROM issues;")
echo -e "${GREEN}$ISSUES_COUNT issues found.${NC}"

# Print summary
echo -e "\n${YELLOW}=== Validation Summary ===${NC}"
echo -e "${GREEN}✓ Docker is running${NC}"
echo -e "${GREEN}✓ Containers are running${NC}"
echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
echo -e "${GREEN}✓ Flyway migrations applied${NC}"
echo -e "${GREEN}✓ Redmine is responding${NC}"
if [ "$ADMIN_RESP" -eq "200" ] && [ "$USER_RESP" -eq "200" ]; then
  echo -e "${GREEN}✓ API keys are valid${NC}"
else
  echo -e "${RED}✗ API key validation failed${NC}"
fi
echo -e "${GREEN}✓ Database contains expected data${NC}"

# Final message
if [ "$ADMIN_RESP" -eq "200" ] && [ "$USER_RESP" -eq "200" ]; then
  echo -e "\n${GREEN}Validation completed successfully.${NC}"
  echo -e "${YELLOW}Redmine is ready for use with the MCP server.${NC}"
  echo -e "- Admin user: admin / admin"
  echo -e "- Test user: testuser / password"
  echo -e "- Access Redmine at: http://localhost:3000"
else
  echo -e "\n${RED}Validation completed with issues.${NC}"
  echo -e "${YELLOW}Please check the logs for more details.${NC}"
fi

exit 0
