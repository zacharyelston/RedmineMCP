# Redmine Server - Development Test Bench

This component provides a Flyway-based migration setup for Redmine's PostgreSQL database. It is designed as a development test bench for the Redmine MCP project.

## Overview

The Redmine Server component provides:

1. Incremental database migrations for Redmine using Flyway
2. Basic user setup with predefined API keys
3. Sample test data for functional testing
4. Documentation for the database structure

## Directory Structure

```
redmine-server/
├── docker-compose.yml      # Docker configuration for Redmine and PostgreSQL
├── flyway.conf             # Flyway configuration
├── .env.example            # Environment variable template
├── sql/                    # SQL scripts
│   ├── migrations/         # Versioned migration scripts
│   └── callbacks/          # Flyway callback scripts
├── scripts/                # Utility scripts
│   └── validate.sh         # Validation script
└── README.md               # This documentation file
```

## Migration Structure

The migrations are organized in functional groups:

1. `V1__Base_Schema.sql` - Core database schema
2. `V2__User_Management.sql` - User accounts and authentication
3. `V3__Project_Structure.sql` - Projects and modules
4. `V4__Issue_Tracking.sql` - Issue tracking functionality
5. `V5__Workflow_Engine.sql` - Workflow definitions
6. `V6__Sample_Data.sql` - Test data for development

## Usage

### Prerequisites

1. Docker and Docker Compose
2. Flyway CLI (optional, for running migrations outside Docker)

### Running the Test Bench

1. Start the environment:
   ```bash
   docker-compose up -d
   ```

2. Apply migrations:
   ```bash
   docker-compose run --rm flyway migrate
   ```

3. Validate the setup:
   ```bash
   ./scripts/validate.sh
   ```

## Default Credentials

The following users are created with predefined API keys for development purposes:

| User     | Username  | Password  | API Key                                  | Role      |
|----------|-----------|-----------|------------------------------------------|-----------|
| Admin    | admin     | admin     | 7a4ed5c91b405d30fda60909dbc86c2651c38217 | Admin     |
| Test User| testuser  | password  | 3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0 | Reporter  |
| Developer| developer | developer | f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f | Developer |
| Manager  | manager   | manager   | 5c98f85a9f2e34c3b217758e910e196c7a77bf5b | Manager   |

These predefined API keys make it easier for developers to test MCP integration without having to generate new keys for each setup. An example `credentials.yaml` file is provided in the project root for reference.

## Sample Data

The following sample data is included:

- Projects: MCP Development, API Testing, Documentation
- Users: Admin, Test User, Developer, Manager
- Issues: Several sample issues across different projects
- Time entries: Sample time tracking data
- Custom fields: Testing Environment field for issues

## Integration with Redmine MCP

This component serves as a consistent development database for the Redmine MCP project. The predefined API keys and test data ensure that the MCP server can be validated against a known database state.

To integrate with the MCP server:

1. Start the Redmine server using Docker Compose
2. Configure the MCP server to use one of the predefined API keys
3. Run the validation script to ensure the environment is correctly set up
4. Use the MCP server to interact with the Redmine instance

## Security Note

This setup is intended for development and testing purposes only. The default credentials and configuration are not suitable for production use. The predefined API keys are included for convenience in the development environment only.

## Process Adherence

Following the project principles:

1. **Process Over Speed**: Migrations are incremental and grouped by function
2. **Validation Gates**: Each migration can be validated independently
3. **Documentation First**: Database structure is documented
4. **Security Through Repetition**: Consistent database setup process

Remember: How slowly you work is an indication of how careful you are. Process is the key and provides security through repetition.
