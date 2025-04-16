# Role-Based MCP Server Configuration - Implementation Plan

## Current Status

We've designed and created the foundational framework for generating role-based MCP server configurations:

1. Created a YAML to SQL converter script (`yaml_to_sql.js`)
2. Built the supporting library components:
   - YAML configuration validators
   - SQL generators for roles, users, custom fields, and memberships
   - Setup script generators for MCP server instances
3. Provided sample role configurations for Developer and Project Manager roles
4. Added documentation to explain the system

## Next Steps

### 1. Integration with MCP Server Codebase

- [ ] Extend the MCP server to load role-specific configuration
- [ ] Modify the main server code to filter available tools based on role configuration
- [ ] Create a role-aware middleware layer for command execution
- [ ] Update the server's startup process to load behavioral patterns

### 2. Role-Specific Behavior Implementation

- [ ] Create a behavior module that applies role-specific patterns to responses
- [ ] Implement context awareness based on role focus areas
- [ ] Add support for customized command output based on communication style
- [ ] Develop a system for role-appropriate decision making based on defined thresholds

### 3. Deployment and Instance Management

- [ ] Create a deployment script for multiple role-based MCP instances
- [ ] Develop a simple dashboard for monitoring running instances
- [ ] Add support for role instance logs and monitoring
- [ ] Create a system for updating role configurations across instances

### 4. Testing and Validation

- [ ] Develop unit tests for all components of the role-sync system
- [ ] Create integration tests for role-based behavior
- [ ] Build test scenarios for multi-role workflows
- [ ] Validate security boundaries between role instances

### 5. Additional Roles and Refinement

- [ ] Create configuration files for additional roles:
  - [ ] QA/Tester role
  - [ ] Documentation Specialist role
  - [ ] DevOps Engineer role
  - [ ] Product Owner role
- [ ] Refine role permissions and custom fields based on testing
- [ ] Add more sophisticated behavioral patterns based on role requirements

### 6. MCP Server Modifications

#### Loader Module

```javascript
// Location: ../../src/core/RoleConfigLoader.ts

import fs from 'fs';
import path from 'path';
import yaml from 'js-yaml';

/**
 * Loads and manages role-specific configuration for the MCP server
 */
export class RoleConfigLoader {
  private config: any;
  private roleName: string;
  private readonly configPath: string;

  constructor(configPath: string) {
    this.configPath = configPath;
    this.loadConfig();
  }

  /**
   * Load the role configuration from YAML file
   */
  private loadConfig(): void {
    try {
      const configContent = fs.readFileSync(this.configPath, 'utf8');
      this.config = yaml.load(configContent);
      
      if (!this.config || !this.config.role || !this.config.role.name) {
        throw new Error('Invalid role configuration: missing role name');
      }
      
      this.roleName = this.config.role.name;
      console.log(`Loaded configuration for role: ${this.roleName}`);
    } catch (error) {
      console.error('Failed to load role configuration:', error);
      throw error;
    }
  }

  /**
   * Get the role name
   */
  getRoleName(): string {
    return this.roleName;
  }

  /**
   * Get the full role configuration
   */
  getConfig(): any {
    return this.config;
  }

  /**
   * Check if a specific MCP tool is available for this role
   */
  isToolAvailable(toolName: string): boolean {
    if (!this.config.mcp_server_config || 
        !this.config.mcp_server_config.available_tools || 
        !Array.isArray(this.config.mcp_server_config.available_tools)) {
      return false;
    }

    return this.config.mcp_server_config.available_tools.includes(toolName);
  }

  /**
   * Get behavioral patterns for this role
   */
  getBehavioralPatterns(): any {
    return this.config.role.behavioral_patterns || {};
  }

  /**
   * Check if a command is allowed for this role
   */
  isCommandAllowed(command: string): boolean {
    if (!this.config.mcp_server_config || 
        !this.config.mcp_server_config.allowed_commands || 
        !Array.isArray(this.config.mcp_server_config.allowed_commands)) {
      return false;
    }

    // Check if the command or any prefix of it is in the allowed list
    return this.config.mcp_server_config.allowed_commands.some((allowedCmd: string) => {
      return command === allowedCmd || command.startsWith(`${allowedCmd} `);
    });
  }
}
```

#### MCP Server Integration

```javascript
// Location: ../../src/core/RoleBasedMcpServer.ts

import { RoleConfigLoader } from './RoleConfigLoader';
import { MCPServer } from './MCPServer'; // Existing MCP server class

/**
 * Role-specific MCP server that loads and applies role-based configuration
 */
export class RoleBasedMcpServer extends MCPServer {
  private roleConfig: RoleConfigLoader;

  constructor(configPath: string) {
    super();
    this.roleConfig = new RoleConfigLoader(configPath);
    this.applyRoleConfiguration();
  }

  /**
   * Apply role-specific configuration to the server
   */
  private applyRoleConfiguration(): void {
    const config = this.roleConfig.getConfig();
    const roleName = this.roleConfig.getRoleName();

    console.log(`Configuring MCP server for role: ${roleName}`);

    // Set server properties based on role config
    if (config.mcp_server_config) {
      if (config.mcp_server_config.port) {
        this.port = config.mcp_server_config.port;
      }
      
      if (config.mcp_server_config.log_level) {
        this.logLevel = config.mcp_server_config.log_level;
      }
      
      // Additional server configuration as needed
    }

    // Register command middleware for role-based filtering
    this.registerCommandMiddleware(this.roleCommandFilterMiddleware.bind(this));
  }

  /**
   * Middleware that filters commands based on role permissions
   */
  private roleCommandFilterMiddleware(command: string, args: any, next: Function): void {
    const commandName = command.split('_')[0]; // Extract base command name
    
    if (!this.roleConfig.isToolAvailable(commandName)) {
      return next(new Error(`The command '${commandName}' is not available for the ${this.roleConfig.getRoleName()} role`));
    }

    // For execute_command, check if the specific command is allowed
    if (commandName === 'execute_command' && args.command) {
      if (!this.roleConfig.isCommandAllowed(args.command)) {
        return next(new Error(`The shell command '${args.command}' is not allowed for the ${this.roleConfig.getRoleName()} role`));
      }
    }

    // Proceed to next middleware or command execution
    next();
  }

  /**
   * Get behavioral patterns for response formatting
   */
  getBehavioralPatterns(): any {
    return this.roleConfig.getBehavioralPatterns();
  }
}
```

## Testing Approach

1. **Unit Testing**:
   - Create tests for each role configuration validator
   - Test SQL generation for different role types
   - Validate command filtering middleware

2. **Integration Testing**:
   - Test complete flow from YAML to SQL to server setup
   - Validate that role permissions are correctly enforced
   - Ensure custom fields are properly associated with roles

3. **Manual Testing Checklist**:
   - [ ] Run YAML validation on sample roles
   - [ ] Generate SQL and verify correctness
   - [ ] Apply SQL to test Redmine instance
   - [ ] Configure and start role-specific MCP server
   - [ ] Test command execution with role-specific permissions
   - [ ] Validate behavioral patterns are applied correctly

## Deployment Strategy

1. Create one MCP server instance per role with:
   - Role-specific configuration
   - Dedicated port
   - Role-appropriate API key

2. Use environment variables or config files to point Claude to the appropriate MCP instance based on its assigned role

3. Configure load balancing if multiple instances of the same role are needed

## Time Estimate and Priorities

| Task | Priority | Estimated Effort | Dependencies |
|------|----------|------------------|--------------|
| Complete base YAML/SQL conversion | High | 2 days | None |
| Integrate with MCP server | High | 3 days | Base conversion |
| Implement role-based behavior | Medium | 4 days | MCP integration |
| Create additional roles | Medium | 2 days | Base conversion |
| Deployment automation | Low | 3 days | All above tasks |
| Testing and validation | High | Ongoing | Each component |

## Role Profile Database Schema

For the SQL generation, we need to ensure we're creating the appropriate database structures. Here's the basic schema for role-based Redmine configuration:

```sql
-- Roles table (existing in Redmine)
CREATE TABLE IF NOT EXISTS roles (
  id int(11) NOT NULL AUTO_INCREMENT,
  name varchar(30) NOT NULL,
  position int(11) NOT NULL DEFAULT '1',
  assignable tinyint(1) NOT NULL DEFAULT '1',
  builtin int(11) NOT NULL DEFAULT '0',
  permissions text,
  issues_visibility varchar(30) NOT NULL DEFAULT 'default',
  users_visibility varchar(30) NOT NULL DEFAULT 'all',
  time_entries_visibility varchar(30) NOT NULL DEFAULT 'all',
  all_roles_managed tinyint(1) NOT NULL DEFAULT '1',
  settings text,
  PRIMARY KEY (id)
);

-- Custom fields (existing in Redmine)
CREATE TABLE IF NOT EXISTS custom_fields (
  id int(11) NOT NULL AUTO_INCREMENT,
  type varchar(30) NOT NULL DEFAULT '',
  name varchar(30) NOT NULL DEFAULT '',
  field_format varchar(30) NOT NULL DEFAULT '',
  possible_values text,
  regexp varchar(255) DEFAULT '',
  min_length int(11) DEFAULT NULL,
  max_length int(11) DEFAULT NULL,
  is_required tinyint(1) NOT NULL DEFAULT '0',
  is_for_all tinyint(1) NOT NULL DEFAULT '0',
  is_filter tinyint(1) NOT NULL DEFAULT '0',
  position int(11) DEFAULT NULL,
  searchable tinyint(1) DEFAULT '0',
  default_value text,
  editable tinyint(1) DEFAULT '1',
  visible tinyint(1) DEFAULT '1',
  multiple tinyint(1) DEFAULT '0',
  format_store text,
  description text,
  PRIMARY KEY (id)
);

-- Custom fields and roles association (existing in Redmine)
CREATE TABLE IF NOT EXISTS custom_fields_roles (
  custom_field_id int(11) NOT NULL,
  role_id int(11) NOT NULL,
  UNIQUE KEY index_custom_fields_roles_on_custom_field_id_and_role_id (custom_field_id,role_id)
);
```

## Conclusion

This implementation plan provides a roadmap for completing the role-based MCP server configuration system. By following these steps, we'll create a flexible, role-aware system that can adapt the behavior, permissions, and tools available to different AI agent roles.

The integration with the existing MCP server code should be done carefully to maintain backward compatibility while adding the new role-based functionality. Testing at each stage will ensure that the system behaves correctly and securely enforces role boundaries.
