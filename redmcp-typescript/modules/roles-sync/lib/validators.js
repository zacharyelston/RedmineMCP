/**
 * validators.js
 * 
 * Validation utilities for role configuration YAML files
 */

// List of valid permission names in Redmine
const VALID_PERMISSIONS = [
  // Project permissions
  'view_project', 'manage_project', 'edit_project', 'close_project',
  'select_project_modules', 'manage_members', 'create_subprojects',
  
  // Issue permissions
  'view_issues', 'add_issues', 'edit_issues', 'delete_issues',
  'manage_issue_relations', 'manage_subtasks', 'set_issues_private',
  'set_own_issues_private', 'add_issue_notes', 'edit_issue_notes',
  'edit_own_issue_notes', 'view_private_notes', 'set_notes_private',
  'move_issues', 'delete_issues', 'manage_related_issues',
  
  // Time tracking
  'log_time', 'view_time_entries', 'edit_time_entries', 'edit_own_time_entries',
  'manage_project_activities',
  
  // News & Documents
  'manage_news', 'comment_news', 'manage_documents', 'view_documents',
  
  // Files & Attachments
  'manage_files', 'view_files', 'manage_wiki', 'rename_wiki_pages',
  'delete_wiki_pages', 'view_wiki_pages', 'export_wiki_pages',
  'view_wiki_edits', 'edit_wiki_pages', 'delete_wiki_pages_attachments',
  'protect_wiki_pages',
  
  // Repository
  'manage_repository', 'browse_repository', 'view_changesets', 'commit_access',
  
  // Forums
  'manage_boards', 'add_messages', 'edit_messages', 'edit_own_messages',
  'delete_messages', 'delete_own_messages',
  
  // Calendar & Gantt
  'view_calendar', 'view_gantt',
  
  // Workflow
  'manage_issue_statuses', 'manage_workflow',
  
  // Admin-level
  'add_project', 'edit_project', 'select_project_modules',
  'manage_categories', 'manage_versions'
];

// List of valid custom field types
const VALID_FIELD_TYPES = [
  'string', 'text', 'int', 'float', 'date', 'bool', 
  'list', 'user', 'version', 'attachment'
];

/**
 * Validates a role configuration object
 * 
 * @param {Object} config - The role configuration object
 * @returns {Object} An object with isValid flag and array of error messages
 */
function validateRoleConfig(config) {
  const errors = [];
  
  // Check if config has a role object
  if (!config.role) {
    errors.push('Missing role object in configuration');
    return { isValid: false, errors };
  }
  
  // Validate role name
  if (!config.role.name) {
    errors.push('Role must have a name');
  } else if (typeof config.role.name !== 'string') {
    errors.push('Role name must be a string');
  } else if (config.role.name.length < 2 || config.role.name.length > 30) {
    errors.push('Role name must be between 2 and 30 characters');
  }
  
  // Validate role description
  if (!config.role.description) {
    errors.push('Role must have a description');
  } else if (typeof config.role.description !== 'string') {
    errors.push('Role description must be a string');
  }
  
  // Validate permissions
  if (!config.role.permissions || !Array.isArray(config.role.permissions)) {
    errors.push('Role must have a permissions array');
  } else {
    config.role.permissions.forEach(permission => {
      if (!VALID_PERMISSIONS.includes(permission)) {
        errors.push(`Invalid permission: ${permission}`);
      }
    });
  }
  
  // Validate custom fields
  if (config.role.custom_fields) {
    if (!Array.isArray(config.role.custom_fields)) {
      errors.push('custom_fields must be an array');
    } else {
      config.role.custom_fields.forEach((field, index) => {
        // Check required field properties
        if (!field.name) {
          errors.push(`Custom field at index ${index} must have a name`);
        }
        
        if (!field.type) {
          errors.push(`Custom field '${field.name || index}' must have a type`);
        } else if (!VALID_FIELD_TYPES.includes(field.type)) {
          errors.push(`Custom field '${field.name || index}' has invalid type: ${field.type}`);
        }
        
        // Check type-specific validations
        if (field.type === 'list' && (!field.possible_values || !Array.isArray(field.possible_values) || field.possible_values.length === 0)) {
          errors.push(`Custom field '${field.name || index}' of type 'list' must have non-empty possible_values array`);
        }
        
        // Validate default value matches the type
        if (field.default_value !== undefined && field.default_value !== null && field.default_value !== '') {
          if (field.type === 'int' && !Number.isInteger(Number(field.default_value))) {
            errors.push(`Custom field '${field.name || index}' has invalid default value for type 'int': ${field.default_value}`);
          } else if (field.type === 'float' && isNaN(Number(field.default_value))) {
            errors.push(`Custom field '${field.name || index}' has invalid default value for type 'float': ${field.default_value}`);
          } else if (field.type === 'bool' && ![true, false, 'true', 'false', 0, 1, '0', '1'].includes(field.default_value)) {
            errors.push(`Custom field '${field.name || index}' has invalid default value for type 'bool': ${field.default_value}`);
          } else if (field.type === 'list' && !field.possible_values.includes(field.default_value)) {
            errors.push(`Custom field '${field.name || index}' has default value not in possible_values: ${field.default_value}`);
          }
        }
      });
    }
  }
  
  // Validate behavioral patterns (if present)
  if (config.role.behavioral_patterns) {
    // These are optional but if present should follow the correct structure
    const bp = config.role.behavioral_patterns;
    
    if (bp.focus_areas && !Array.isArray(bp.focus_areas)) {
      errors.push('behavioral_patterns.focus_areas must be an array');
    }
    
    if (bp.communication_style) {
      if (typeof bp.communication_style !== 'object') {
        errors.push('behavioral_patterns.communication_style must be an object');
      }
    }
    
    if (bp.decision_making) {
      if (typeof bp.decision_making !== 'object') {
        errors.push('behavioral_patterns.decision_making must be an object');
      }
    }
  }
  
  // Check for mcp_server_config section (required)
  if (!config.mcp_server_config) {
    errors.push('Missing mcp_server_config section');
  } else {
    // Validate API key
    if (!config.mcp_server_config.api_key) {
      errors.push('mcp_server_config must include an api_key');
    }
    
    // Validate server instance name
    if (!config.mcp_server_config.instance_name) {
      errors.push('mcp_server_config must include an instance_name');
    }
    
    // Validate available tools (must be an array)
    if (!config.mcp_server_config.available_tools || !Array.isArray(config.mcp_server_config.available_tools)) {
      errors.push('mcp_server_config must include an available_tools array');
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

module.exports = {
  validateRoleConfig,
  VALID_PERMISSIONS,
  VALID_FIELD_TYPES
};
