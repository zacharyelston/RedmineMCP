/**
 * role-generator.js
 * 
 * Generates SQL for creating and configuring Redmine roles
 */

/**
 * Generate SQL for creating a role based on role configuration
 * 
 * @param {Object} config - The role configuration object
 * @returns {string} SQL statements for creating the role
 */
function generateRoleSql(config) {
  const { role } = config;
  
  // Convert permissions array to YAML format for Redmine storage
  const permissionsYaml = `---\n${role.permissions.map(p => `- :${p}`).join('\n')}`;
  
  // Generate SQL script - using the same pattern as in create_workflow_manager_role.sql
  return `
-- Check if the ${role.name} role already exists
SET @role_exists = (SELECT COUNT(*) FROM roles WHERE name = '${role.name}');

-- Create the role if it doesn't exist
INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility)
SELECT 
  '${role.name}', 
  (SELECT MAX(position) + 1 FROM roles), 
  1, -- Assignable
  0, -- Not built-in
  '${permissionsYaml}',
  '${role.issues_visibility || 'all'}',
  '${role.users_visibility || 'all'}',
  '${role.time_entries_visibility || 'all'}'
WHERE @role_exists = 0;

-- Get the role ID for later use
SET @role_id = (SELECT id FROM roles WHERE name = '${role.name}');

-- Log result
SELECT 
  CASE 
    WHEN @role_exists = 0 THEN CONCAT('Created new role: ${role.name} with ID ', @role_id)
    ELSE CONCAT('Role ${role.name} already exists with ID ', @role_id)
  END AS 'Role Setup Result';
`.trim();
}

module.exports = {
  generateRoleSql
};
