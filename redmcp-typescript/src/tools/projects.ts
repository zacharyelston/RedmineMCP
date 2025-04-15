/**
 * Project Tools Module
 * Provides MCP tools for interacting with Redmine projects
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register project-related tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerProjectTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register redmine_projects_list tool
  server.registerTool({
    name: "redmine_projects_list",
    description: "List all accessible Redmine projects",
    schema: z.object({
      limit: z.number().optional().describe("Number of projects to return (default: 25)"),
      offset: z.number().optional().describe("Pagination offset (default: 0)"),
      sort: z.string().optional().describe("Field to sort by with direction (default: name:asc)")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { limit?: number; offset?: number; sort?: string }) => {
      try {
        log.info(`Executing redmine_projects_list with params:`, params);
        
        const limit = params.limit || 25;
        const offset = params.offset || 0;
        const sort = params.sort || 'name:asc';
        
        log.debug(`Fetching projects with limit: ${limit}, offset: ${offset}, sort: ${sort}`);
        
        const projects = await dataProvider.getProjects(limit, offset, sort);
        log.info(`Found ${projects.length} projects`);
        
        return projects;
      } catch (error) {
        log.error(`Error in redmine_projects_list:`, error);
        throw new Error(`Failed to list Redmine projects: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_projects_get tool
  server.registerTool({
    name: "redmine_projects_get",
    description: "Get details of a specific Redmine project",
    schema: z.object({
      identifier: z.string().describe("Project identifier"),
      include: z.array(z.string()).optional().describe("Related data to include (e.g. trackers, issue_categories)")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { identifier: string; include?: string[] }) => {
      try {
        log.info(`Executing redmine_projects_get with params:`, params);
        
        const identifier = params.identifier;
        const include = params.include || [];
        
        log.debug(`Fetching project ${identifier} with include: ${include.join(', ')}`);
        
        const project = await dataProvider.getProject(identifier, include);
        log.info(`Found project: ${project.name} (ID: ${project.id})`);
        
        return project;
      } catch (error) {
        log.error(`Error in redmine_projects_get:`, error);
        throw new Error(`Failed to get Redmine project: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_projects_create tool
  server.registerTool({
    name: "redmine_projects_create",
    description: "Create a new Redmine project",
    schema: z.object({
      name: z.string().describe("Project name"),
      identifier: z.string().describe("Project identifier (used in URLs)"),
      description: z.string().optional().describe("Project description"),
      is_public: z.boolean().optional().describe("Whether the project is public (default: true)"),
      parent_id: z.number().optional().describe("Parent project ID for creating a subproject")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { 
      name: string; 
      identifier: string; 
      description?: string; 
      is_public?: boolean; 
      parent_id?: number 
    }) => {
      try {
        log.info(`Executing redmine_projects_create with params:`, params);
        
        const name = params.name;
        const identifier = params.identifier;
        const description = params.description;
        const isPublic = params.is_public === undefined ? true : params.is_public;
        const parentId = params.parent_id;
        
        log.debug(`Creating project "${name}" with identifier "${identifier}", public: ${isPublic}, parentId: ${parentId || 'none'}`);
        
        // Check if createProject method exists on dataProvider
        if (!dataProvider.createProject) {
          throw new Error('createProject method is not available on the data provider');
        }
        
        const project = await dataProvider.createProject(name, identifier, description, isPublic, parentId);
        log.info(`Created project: ${project.name} (ID: ${project.id})`);
        
        return project;
      } catch (error) {
        log.error(`Error in redmine_projects_create:`, error);
        throw new Error(`Failed to create Redmine project: ${(error as Error).message}`);
      }
    }
  });
}
