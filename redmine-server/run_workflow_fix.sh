#!/bin/bash
# run_workflow_fix.sh
# Execute workflow SQL fixes using Docker
# Created for MCP Issue #103 - Workflow Configuration Fix

# Set variables
CONTAINER=$(docker ps -qf "name=redmine")
DB_USER="redmine"
DB_NAME="redmine"
DB_PASSWORD="redmine" # Replace with your actual DB password if different

echo "=== Redmine Workflow Fix Script ==="
echo "Running SQL scripts on container: $CONTAINER"

if [ -z "$CONTAINER" ]; then
  echo "Error: Redmine container not found. Make sure Redmine is running."
  exit 1
fi

# Function to run SQL files in the container
run_sql_file() {
  local file=$1
  echo ""
  echo "Running SQL file: $file"
  echo "------------------------"
  docker exec -i $CONTAINER bash -c "cat > /tmp/temp.sql" < "$file"
  docker exec -i $CONTAINER bash -c "mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME < /tmp/temp.sql"
  echo "------------------------"
  echo "Completed running: $file"
}

# Run the fix script
echo -e "\n=== Fixing workflow configurations ==="
run_sql_file "/redmine-mcp/redmine-server/sql/fix_workflows_complete.sql"

# Create workflow manager role (optional)
echo -e "\n=== Creating workflow manager role ==="
run_sql_file "/redmine-mcp/redmine-server/sql/create_workflow_manager_role.sql"  

# Verify the changes
echo -e "\n=== Verifying workflow configurations ==="
run_sql_file "/redmine-mcp/redmine-server/sql/verify_workflows.sql"

echo -e "\n=== Workflow fixes completed ==="
echo "You should now be able to update issue #93 status to 'Closed'"
echo "Workflow Manager credentials:"
echo "  Username: workflow_manager"
echo "  Password: workflow123"
echo "  API Key: See output from create_workflow_manager_role.sql script above"
echo ""
echo "To close issue #93 using the API, run:"
echo "docker exec -i $CONTAINER curl -X PUT -H \"Content-Type: application/json\" -H \"X-Redmine-API-Key: 7a4ed5c91b405d30fda60909dbc86c2651c38217\" -d '{\"issue\":{\"status_id\":5,\"notes\":\"Closing after workflow fix\"}}' http://localhost:3000/issues/93.json"
