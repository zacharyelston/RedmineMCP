/**
 * redmine_projects_create - Create a new project or subproject in Redmine
 * 
 * This implements the missing MCP function for project creation to complement
 * the existing Redmine MCP tools.
 */
import { RedmineClient } from './RedmineClient.js';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';

// Handle ES modules __dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

/**
 * Create a new project or subproject in Redmine
 * @param {object} options - Project creation options
 * @param {string} options.name - Project name
 * @param {string} options.identifier - Project identifier (slug)
 * @param {string} [options.description] - Project description
 * @param {boolean} [options.is_public=true] - Whether the project is public
 * @param {number} [options.parent_id] - Parent project ID for subproject creation
 * @param {string} [options.todo_file_path] - Path to todo.yaml file for error logging
 * @return {Promise<object>} - Created project data
 */
export async function redmine_projects_create({
  name,
  identifier,
  description,
  is_public = true,
  parent_id,
  todo_file_path
}) {
  console.error('MCP Function: redmine_projects_create');
  console.error(`Creating project: "${name}" (${identifier})`);
  
  // Parameter validation
  if (!name || typeof name !== 'string' || name.trim() === '') {
    throw new Error('Project name is required');
  }
  
  if (!identifier || typeof identifier !== 'string' || identifier.trim() === '') {
    throw new Error('Project identifier is required');
  }
  
  // Get Redmine URL and API key from environment variables
  const redmineUrl = process.env.REDMINE_URL || 'http://localhost:3000';
  const redmineApiKey = process.env.REDMINE_API_KEY || '';
  
  if (!redmineApiKey) {
    throw new Error('Redmine API key not configured. Set REDMINE_API_KEY environment variable.');
  }
  
  // Use provided todo file path or default
  const todoFilePath = todo_file_path || path.resolve(__dirname, '../../../todo.yaml');
  
  // Create Redmine client
  const redmineClient = new RedmineClient(redmineUrl, redmineApiKey, todoFilePath);
  
  try {
    // Create the project using RedmineClient
    const project = await redmineClient.createProject(
      name,
      identifier,
      description,
      is_public,
      parent_id
    );
    
    console.error(`Project created successfully. ID: ${project.id}`);
    return project;
  } catch (error) {
    console.error(`Failed to create project: ${error.message}`);
    throw error;
  }
}

// Export default for CommonJS compatibility
export default redmine_projects_create;
