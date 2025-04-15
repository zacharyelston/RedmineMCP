# Redmine MCP Migrations

## Overview

This document explains the Redmine migration process for the ModelContextProtocol (MCP) implementation. The migrations set up users, projects, issues, and workflows in a Redmine instance.

## Migration Files

The migration SQL files are located in `/redmine-mcp/redmine-server/sql/migrations/`:

1. **V7__User_Accounts_Fixed.sql**: Creates users with API keys
   - Admin user (updated)
   - testuser
   - developer
   - manager

2. **V8__Create_Default_Project.sql**: Creates the MCP project
   - Project configuration
   - Enabled modules
   - Issue categories
   - Versions

3. **V9__Sample_Issues.sql**: Creates sample issues
   - Bug issues
   - Feature requests
   - Tasks
   - Support issues

4. **V10__User_Project_Roles.sql**: Assigns users to roles in the project
   - Developer role
   - Manager role
   - Reporter role

## API Keys for Testing

The API keys have been shortened to 40 characters to match the Redmine database schema:

- Admin: `7a4ed5c91b405d30fda60909dbc86c26`
- Test User: `3e9b7b22b84a26e7e95b3d73b6e65f6c`
- Developer: `f91c59b0d78f2a10d9b7ea3c631d9f2c`
- Manager: `5c98f85a9f2e34c3b217758e910e196c`

## Scripts

### apply-migrations.sh

This script applies all migrations in the correct order. It:

1. Checks if the Redmine and PostgreSQL containers are running
2. Applies each migration SQL file in sequence
3. Verifies that each migration was successful

### verify-migrations.sh

This script verifies that the migrations were correctly applied by:

1. Checking API connectivity using each user's API key
2. Retrieving and validating project data
3. Retrieving and validating issue data
4. Retrieving and validating time entry data
5. Generating summary reports in the validation directory

## Running the Migration Process

1. Ensure Docker is running with the Redmine containers:
   ```
   cd /redmine-mcp/docker
   docker-compose up -d
   ```

2. Apply the migrations:
   ```
   bash /redmine-mcp/scripts/apply-migrations.sh
   ```

3. Verify the migrations:
   ```
   bash /redmine-mcp/scripts/verify-migrations.sh
   ```

4. Check the validation results:
   ```
   cat /redmine-mcp/validation/migration_results/summary.txt
   ```

## Troubleshooting

If migrations fail:

1. Check Docker container logs:
   ```
   docker logs redmine
   docker logs postgres
   ```

2. Check PostgreSQL connection:
   ```
   docker exec -it postgres psql -U redmine -d redmine -c "SELECT 1"
   ```

3. Check for SQL syntax errors:
   ```
   docker exec -it postgres psql -U redmine -d redmine -f /tmp/V7__User_Accounts_Fixed.sql
   ```
