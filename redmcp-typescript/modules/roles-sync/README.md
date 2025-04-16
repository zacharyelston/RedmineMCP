# Role-Based MCP Server Configuration

This tool allows you to create and manage role-specific MCP server instances, each with tailored behaviors, permissions, and focus areas. By creating role-specific profiles that map to Redmine roles, you can create specialized AI workers with appropriately scoped access and behavioral patterns.

## Overview

The tool takes YAML configuration files that define roles and their properties, and generates:

1. SQL scripts to set up the roles, users, and custom fields in Redmine
2. Shell scripts to set up and run role-specific MCP server instances
3. Configuration files for each MCP server instance

## Requirements

- Node.js 14 or higher
- MySQL client (for running the generated SQL scripts)
- Redmine instance (for actually using the generated roles)
- MCP server codebase

## Installation

1. Navigate to the roles-sync directory
2. Install dependencies:

```bash
npm install
```

## Usage

### Creating Role Configuration Files

Role configuration files are written in YAML and should be placed in a directory (e.g., `./role-configs`). See the `samples` directory for example configuration files.

Basic structure of a role configuration:

```yaml
role:
  name: "RoleName"
  description: "Role description"
  permissions:
    - permission1
    - permission2
  custom_fields:
    - name: "field_name"
      type: "field_type"
      # ...other field properties
  behavioral_patterns:
    # behavioral patterns for AI agents

mcp_server_config:
  instance_name: "role_agent_name"
  api_key: "unique_api_key_for_this_role"
  # ...other server configuration
```

### Validating Configuration Files

To validate your YAML configuration files without generating SQL:

```bash
npm run validate --config=./your-config-directory
# Or
node yaml_to_sql.js --validate --config=./your-config-directory
```

### Generating SQL and Setup Scripts

To generate SQL scripts and setup shell scripts:

```bash
npm run generate --config=./your-config-directory --output=./output-directory
# Or
node yaml_to_sql.js --config=./your-config-directory --output=./output-directory
```

### Setting Up a Role-Specific MCP Server Instance

After generating the scripts:

1. Navigate to the output directory
2. Make the shell script executable (if not already):
   ```bash
   chmod +x role_name_setup.sh
   ```
3. Run the setup script:
   ```bash
   ./role_name_setup.sh
   ```
4. Follow the prompts to execute the SQL script and configure the instance
5. Start the MCP server instance using the provided instructions

## Role Configuration Reference

### Role Properties

| Property | Description |
|----------|-------------|
| `name` | Name of the role (required) |
| `description` | Description of the role (required) |
| `permissions` | Array of Redmine permissions (required) |
| `issues_visibility` | Issue visibility level (default: "all") |
| `users_visibility` | User visibility level (default: "all") |
| `time_entries_visibility` | Time entry visibility level (default: "all") |
| `custom_fields` | Array of custom fields for this role |
| `behavioral_patterns` | Behavioral patterns for AI agents with this role |

### Custom Field Properties

| Property | Description |
|----------|-------------|
| `name` | Name of the custom field (required) |
| `type` | Field type: string, text, int, float, date, bool, list, user, version, attachment (required) |
| `possible_values` | Array of possible values (required for list type) |
| `default_value` | Default value for the field |
| `is_required` | Whether the field is required (default: false) |
| `is_filter` | Whether the field can be used as a filter (default: false) |