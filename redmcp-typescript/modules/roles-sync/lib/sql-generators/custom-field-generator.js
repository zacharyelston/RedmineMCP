/**
 * custom-field-generator.js
 * 
 * Generates SQL for creating custom fields for roles
 */

/**
 * Convert JavaScript value to SQL value representation
 * 
 * @param {any} value - The value to convert
 * @param {string} type - The field type
 * @returns {string} SQL representation of the value
 */
function sqlValue(value, type) {
  if (value === null || value === undefined || value === '') {
    return 'NULL';
  }
  
  switch (type) {
    case 'int':
    case 'float':
      return Number(value);
    case 'bool':
      // Convert various boolean representations to 0/1
      if ([true, 'true', 1, '1'].includes(value)) {
        return '1';
      }
      return '0';
    case 'list':
    case 'string':
    case 'text':
    default:
      // Escape single quotes for string values
      return `'${String(value).replace(/'/g, "''")}'`;
  }
}

/**
 * Convert custom field type to Redmine field_format
 * 
 * @param {string} type - YAML config field type
 * @returns {string} Redmine field_format
 */
function mapFieldType(type) {
  const typeMap = {
    'string': 'string',
    'text': 'text',
    'int': 'int',
    'float': 'float',
    'date': 'date',
    'bool': 'bool',
    'list': 'list',
    'user': 'user',
    'version': 'version',
    'attachment': 'attachment'
  };
  
  return typeMap[type] || 'string';
}

/**
 * Generate SQL for creating custom fields based on role configuration
 * 
 * @param {Object} config - The role configuration object
 * @returns {string} SQL statements for creating custom fields
 */
function generateCustomFieldSql(config) {
  if (!config.role.custom_fields || config.role.custom_fields.length === 0) {
    return '-- No custom fields defined for this role';
  }
  
  const { role } = config;
  let sql = [];
  
  // Process each custom field
  role.custom_fields.forEach((field, index) => {
    const fieldName = `${role.name}: ${field.name}`;
    const fieldFormat = mapFieldType(field.type);
    const isRequired = field.is_required ? 1 : 0;
    const isFilter = field.is_filter ? 1 : 0;
    const isForAll = field.is_for_all ? 1 : 0;
    const position = index + 1;
    
    // Create the custom field SQL
    sql.push(`
-- Check if the custom field already exists
SET @field_exists_${index} = (SELECT COUNT(*) FROM custom_fields WHERE name = '${fieldName}');

-- Create the custom field if it doesn't exist
INSERT INTO custom_fields (
  type,
  name,
  field_format,
  possible_values,
  regexp,
  min_length,
  max_length,
  is_required,
  is_filter,
  searchable,
  default_value,
  editable,
  visible,
  multiple,
  format_store,
  description,
  position
)
SELECT
  'UserCustomField',
  '${fieldName}',
  '${fieldFormat}',
  ${field.type === 'list' ? `'---\\n- ${field.possible_values.join("\\n- ")}'` : 'NULL'},
  '',
  ${field.min_length || 'NULL'},
  ${field.max_length || 'NULL'},
  ${isRequired},
  ${isFilter},
  ${field.searchable ? 1 : 0},
  ${field.default_value !== undefined ? sqlValue(field.default_value, field.type) : 'NULL'},
  1,
  1,
  ${field.multiple ? 1 : 0},
  '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\\n{}',
  ${field.description ? `'${field.description.replace(/'/g, "''")}'` : 'NULL'},
  ${position}
WHERE @field_exists_${index} = 0;

-- Get the custom field ID for later use
SET @custom_field_id_${index} = (SELECT id FROM custom_fields WHERE name = '${fieldName}');

-- Associate the custom field with the role (via user)
-- This is just the setup to enable these fields for users with this role
INSERT INTO custom_fields_roles (custom_field_id, role_id)
SELECT @custom_field_id_${index}, @role_id
WHERE NOT EXISTS (
  SELECT 1 FROM custom_fields_roles 
  WHERE custom_field_id = @custom_field_id_${index} AND role_id = @role_id
);

-- Log result
SELECT 
  CASE 
    WHEN @field_exists_${index} = 0 THEN CONCAT('Created custom field: ${fieldName} with ID ', @custom_field_id_${index})
    ELSE CONCAT('Custom field ${fieldName} already exists with ID ', @custom_field_id_${index})
  END AS 'Custom Field ${index + 1} Result';`);
  });
  
  return sql.join('\n\n');
}

module.exports = {
  generateCustomFieldSql
};
