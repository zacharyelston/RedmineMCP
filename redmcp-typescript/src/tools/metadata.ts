/**
 * Metadata Tools Module
 * Provides MCP tools for interacting with Redmine metadata
 * (statuses, trackers, priorities, etc.)
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register metadata-related tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerMetadataTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register redmine_issue_statuses tool
  server.registerTool({
    name: "redmine_issue_statuses",
    description: "Get list of issue statuses from Redmine",
    schema: z.object({}),
    handler: async () => {
      try {
        log.info(`Executing redmine_issue_statuses`);
        
        // Check if getIssueStatuses method exists on dataProvider
        if (!dataProvider.getIssueStatuses) {
          throw new Error('getIssueStatuses method is not available on the data provider');
        }
        
        const statuses = await dataProvider.getIssueStatuses();
        log.info(`Found ${statuses.length} issue statuses`);
        
        return statuses;
      } catch (error) {
        log.error(`Error in redmine_issue_statuses:`, error);
        throw new Error(`Failed to get issue statuses: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_trackers tool
  server.registerTool({
    name: "redmine_trackers",
    description: "Get list of trackers from Redmine",
    schema: z.object({}),
    handler: async () => {
      try {
        log.info(`Executing redmine_trackers`);
        
        // Check if getTrackers method exists on dataProvider
        if (!dataProvider.getTrackers) {
          throw new Error('getTrackers method is not available on the data provider');
        }
        
        const trackers = await dataProvider.getTrackers();
        log.info(`Found ${trackers.length} trackers`);
        
        return trackers;
      } catch (error) {
        log.error(`Error in redmine_trackers:`, error);
        throw new Error(`Failed to get trackers: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_issue_priorities tool
  server.registerTool({
    name: "redmine_issue_priorities",
    description: "Get list of issue priorities from Redmine",
    schema: z.object({}),
    handler: async () => {
      try {
        log.info(`Executing redmine_issue_priorities`);
        
        // Check if getIssuePriorities method exists on dataProvider
        if (!dataProvider.getIssuePriorities) {
          throw new Error('getIssuePriorities method is not available on the data provider');
        }
        
        const priorities = await dataProvider.getIssuePriorities();
        log.info(`Found ${priorities.length} issue priorities`);
        
        return priorities;
      } catch (error) {
        log.error(`Error in redmine_issue_priorities:`, error);
        throw new Error(`Failed to get issue priorities: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_activities tool
  server.registerTool({
    name: "redmine_time_entry_activities",
    description: "Get list of time entry activities from Redmine",
    schema: z.object({}),
    handler: async () => {
      try {
        log.info(`Executing redmine_time_entry_activities`);
        
        // Check if getTimeEntryActivities method exists on dataProvider
        if (!dataProvider.getTimeEntryActivities) {
          throw new Error('getTimeEntryActivities method is not available on the data provider');
        }
        
        const activities = await dataProvider.getTimeEntryActivities();
        log.info(`Found ${activities.length} time entry activities`);
        
        return activities;
      } catch (error) {
        log.error(`Error in redmine_time_entry_activities:`, error);
        throw new Error(`Failed to get time entry activities: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_users tool
  server.registerTool({
    name: "redmine_users",
    description: "Get list of users from Redmine",
    schema: z.object({
      project_id: z.number().optional().describe("Optional project ID to filter users")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id?: number }) => {
      try {
        log.info(`Executing redmine_users with params:`, params);
        
        const projectId = params.project_id;
        
        // Check if getUsers method exists on dataProvider
        if (!dataProvider.getUsers) {
          throw new Error('getUsers method is not available on the data provider');
        }
        
        const users = await dataProvider.getUsers(projectId);
        log.info(`Found ${users.length} users${projectId ? ` for project ${projectId}` : ''}`);
        
        return users;
      } catch (error) {
        log.error(`Error in redmine_users:`, error);
        throw new Error(`Failed to get users: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_issue_categories tool
  server.registerTool({
    name: "redmine_issue_categories",
    description: "Get list of issue categories for a project",
    schema: z.object({
      project_id: z.union([z.string(), z.number()]).describe("Project ID or identifier")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id: string | number }) => {
      try {
        log.info(`Executing redmine_issue_categories with params:`, params);
        
        const projectId = params.project_id;
        
        // Check if getIssueCategories method exists on dataProvider
        if (!dataProvider.getIssueCategories) {
          throw new Error('getIssueCategories method is not available on the data provider');
        }
        
        const categories = await dataProvider.getIssueCategories(projectId);
        log.info(`Found ${categories.length} issue categories for project ${projectId}`);
        
        return categories;
      } catch (error) {
        log.error(`Error in redmine_issue_categories:`, error);
        throw new Error(`Failed to get issue categories: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_custom_fields tool
  server.registerTool({
    name: "redmine_custom_fields",
    description: "Get list of custom fields from Redmine",
    schema: z.object({}),
    handler: async () => {
      try {
        log.info(`Executing redmine_custom_fields`);
        
        // Check if getCustomFields method exists on dataProvider
        if (!dataProvider.getCustomFields) {
          throw new Error('getCustomFields method is not available on the data provider');
        }
        
        const customFields = await dataProvider.getCustomFields();
        log.info(`Found ${customFields.length} custom fields`);
        
        return customFields;
      } catch (error) {
        log.error(`Error in redmine_custom_fields:`, error);
        throw new Error(`Failed to get custom fields: ${(error as Error).message}`);
      }
    }
  });
}
