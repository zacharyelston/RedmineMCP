/**
 * setup-generator.js
 * 
 * Generates shell scripts for setting up MCP server instances with role-specific configuration
 */

/**
 * Generate a shell script to set up an MCP server instance for a specific role
 * 
 * @param {Object} config - The role configuration object
 * @param {string} sqlFilename - The base filename for the SQL script (without extension)
 * @returns {string} Shell script content
 */
function generateSetupScript(config, sqlFilename) {
  const { role, mcp_server_config } = config;
  const roleName = role.name.toLowerCase().replace(/\s+/g, '_');
  const instanceName = mcp_server_config.instance_name || `${roleName}_agent`;
  
  // Format the list of available tools
  const availableTools = mcp_server_config.available_tools
    .map(tool => `  - ${tool}`)
    .join('\n');
  
  // Create env file content
  const envFileContent = `
# Environment configuration for ${role.name} MCP server instance
REDMINE_API_URL=http://localhost:3000
REDMINE_API_KEY=${mcp_server_config.api_key}
MCP_ROLE=${role.name}
MCP_INSTANCE_NAME=${instanceName}
PORT=${mcp_server_config.port || '3001'}
ENVIRONMENT=${mcp_server_config.environment || 'development'}
LOG_LEVEL=${mcp_server_config.log_level || 'info'}
`.trim();

  const mcpConfigYaml = `
# MCP Configuration for ${role.name} agent
role:
  name: ${role.name}
  description: ${role.description}

mcp_server:
  instance_name: ${instanceName}
  api_key: ${mcp_server_config.api_key}

available_tools:
${availableTools}

behavioral_patterns:
${formatBehavioralPatterns(role.behavioral_patterns)}
`.trim();

  // Create the setup script
  return `#!/bin/bash
# Setup script for ${role.name} MCP server instance
# Generated automatically by roles-sync

# Define colors for output
GREEN="\\033[0;32m"
RED="\\033[0;31m"
YELLOW="\\033[0;33m"
NC="\\033[0m" # No Color

# Define paths
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SQL_DIR="$SCRIPT_DIR"
CONFIG_DIR="$ROOT_DIR/config"
INSTANCE_DIR="$ROOT_DIR/instances/${instanceName}"

echo -e "${YELLOW}Setting up ${role.name} MCP server instance...${NC}"

# Step 1: Create necessary directories
echo "Creating directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$INSTANCE_DIR"
mkdir -p "$INSTANCE_DIR/config"
mkdir -p "$INSTANCE_DIR/logs"

# Step 2: Create environment file
echo "Creating environment file..."
cat > "$INSTANCE_DIR/.env" << 'EOF'
${envFileContent}
EOF

# Step 3: Create MCP config file
echo "Creating MCP configuration file..."
cat > "$INSTANCE_DIR/config/mcp-config.yaml" << 'EOF'
${mcpConfigYaml}
EOF

# Step 4: Execute SQL setup if requested
read -p "Do you want to execute the SQL setup script now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Executing SQL setup script..."
    
    # Check if we have mysql command
    if command -v mysql &> /dev/null
    then
        # Get database credentials
        read -p "Enter database host [localhost]: " DB_HOST
        DB_HOST=${DB_HOST:-localhost}
        
        read -p "Enter database name [redmine]: " DB_NAME
        DB_NAME=${DB_NAME:-redmine}
        
        read -p "Enter database user [redmine]: " DB_USER
        DB_USER=${DB_USER:-redmine}
        
        read -s -p "Enter database password: " DB_PASS
        echo
        
        # Execute the SQL script
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/${sqlFilename}.sql"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}SQL setup completed successfully!${NC}"
        else
            echo -e "${RED}SQL setup failed. Please check the output above for errors.${NC}"
        fi
    else
        echo -e "${RED}MySQL client not found. Please install it or execute the SQL script manually.${NC}"
        echo "You can run the SQL script with:"
        echo "mysql -u <user> -p <database> < $SQL_DIR/${sqlFilename}.sql"
    fi
fi

# Step 5: Provide MCP server start instructions
echo -e "${GREEN}Setup completed!${NC}"
echo
echo "To start the MCP server instance, run:"
echo "cd $INSTANCE_DIR"
echo "npm start"
echo
echo "API Key for this instance: ${mcp_server_config.api_key}"
echo
echo "Make sure to update your Claude configuration to use this API key."
`;
}

/**
 * Format behavioral patterns as YAML for the config file
 * 
 * @param {Object} patterns - The behavioral patterns object
 * @returns {string} YAML formatted behavioral patterns
 */
function formatBehavioralPatterns(patterns) {
  if (!patterns) {
    return '  # No behavioral patterns defined';
  }
  
  let result = [];
  
  if (patterns.focus_areas && Array.isArray(patterns.focus_areas)) {
    result.push('  focus_areas:');
    patterns.focus_areas.forEach(area => {
      result.push(`    - "${area}"`);
    });
  }
  
  if (patterns.communication_style) {
    result.push('  communication_style:');
    for (const [key, value] of Object.entries(patterns.communication_style)) {
      result.push(`    ${key}: "${value}"`);
    }
  }
  
  if (patterns.decision_making) {
    result.push('  decision_making:');
    for (const [key, value] of Object.entries(patterns.decision_making)) {
      result.push(`    ${key}: "${value}"`);
    }
  }
  
  return result.join('\n');
}

module.exports = {
  generateSetupScript
};
