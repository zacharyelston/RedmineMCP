/**
 * user-generator.js
 * 
 * Generates SQL for creating users associated with roles
 */

const crypto = require('crypto');

/**
 * Generate a secure random password
 * 
 * @returns {string} A random password
 */
function generateRandomPassword() {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Generate a salted SHA-1 hash for a password (Redmine format)
 * 
 * @param {string} password - The password to hash
 * @param {string} salt - The salt to use
 * @returns {string} The hashed password
 */
function hashPassword(password, salt) {
  const hash = crypto.createHash('sha1');
  hash.update(salt + password);
  return hash.digest('hex');
}

/**
 * Generate SQL for creating users based on role configuration
 * 
 * @param {Object} config - The role configuration object
 * @returns {string} SQL statements for creating users
 */
function generateUserSql(config) {
  const { role, mcp_server_config } = config;
  
  // Create a base login name from the role name
  const baseLogin = role.name.toLowerCase().replace(/\s+/g, '_');
  
  // Generate a random password and salt
  const password = generateRandomPassword();
  const salt = crypto.randomBytes(8).toString('hex');
  const hashedPassword = hashPassword(password, salt);
  
  // By default, create one user per role (for the MCP instance)
  const userLogin = `${baseLogin}_agent`;
  
  // Store the API key from the config
  const apiKey = mcp_server_config.api_key;
  
  return `
-- Check if the user already exists
SET @user_exists = (SELECT COUNT(*) FROM users WHERE login = '${userLogin}');

-- Create the user if it doesn't exist
INSERT INTO users (
  login, 
  hashed_password, 
  firstname, 
  lastname, 
  admin, 
  status, 
  last_login_on, 
  language, 
  auth_source_id, 
  created_on, 
  updated_on, 
  type, 
  identity_url, 
  mail_notification, 
  salt, 
  must_change_passwd, 
  passwd_changed_on
)
SELECT 
  '${userLogin}', 
  '${hashedPassword}', 
  '${role.name}', 
  'Agent', 
  0, -- Not admin
  1, -- Active
  NULL, 
  'en', 
  NULL, 
  NOW(), 
  NOW(), 
  'User', 
  NULL, 
  '', 
  '${salt}', 
  0, 
  NOW()
WHERE @user_exists = 0;

-- Get the user ID for later use
SET @user_id = (SELECT id FROM users WHERE login = '${userLogin}');

-- Now create an API token for this user with the specified API key
SET @token_exists = (SELECT COUNT(*) FROM tokens WHERE user_id = @user_id AND action = 'api');

-- Delete any existing tokens for this user (to ensure we use the specified API key)
DELETE FROM tokens WHERE user_id = @user_id AND action = 'api';

-- Create new token with the specified API key
INSERT INTO tokens (
  user_id,
  action,
  value,
  created_on,
  updated_on
)
VALUES (
  @user_id,
  'api',
  '${apiKey}',
  NOW(),
  NOW()
);

-- Log the credentials for reference 
SELECT 
  '${userLogin}' AS username,
  '${password}' AS password,
  '${apiKey}' AS api_key,
  CONCAT('User ID: ', @user_id) AS user_info,
  'Add this API key to your MCP server .env file or configure it in your client' AS note;
`.trim();
}

module.exports = {
  generateUserSql
};
