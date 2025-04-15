/**
 * Time Tracking Tools Module
 * Provides MCP tools for interacting with Redmine time entries
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register time tracking tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerTimeTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register redmine_time_entries_list tool
  server.registerTool({
    name: "redmine_time_entries_list",
    description: "List time entries from Redmine with optional filters",
    schema: z.object({
      issue_id: z.number().optional().describe("Filter by issue ID"),
      project_id: z.number().optional().describe("Filter by project ID"),
      user_id: z.number().optional().describe("Filter by user ID"),
      from: z.string().optional().describe("Filter by start date (YYYY-MM-DD)"),
      to: z.string().optional().describe("Filter by end date (YYYY-MM-DD)"),
      limit: z.number().optional().describe("Maximum number of entries to return (default: 25)"),
      offset: z.number().optional().describe("Pagination offset (default: 0)")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { 
      issue_id?: number;
      project_id?: number;
      user_id?: number;
      from?: string;
      to?: string;
      limit?: number;
      offset?: number;
    }) => {
      try {
        log.info(`Executing redmine_time_entries_list with params:`, params);
        
        const issueId = params.issue_id;
        const projectId = params.project_id;
        const userId = params.user_id;
        const from = params.from;
        const to = params.to;
        const limit = params.limit || 25;
        const offset = params.offset || 0;
        
        log.debug(`Fetching time entries with filters: issue_id=${issueId || 'any'}, project_id=${projectId || 'any'}, user_id=${userId || 'any'}`);
        
        // Check if getTimeEntries method exists on dataProvider
        if (!dataProvider.getTimeEntries) {
          throw new Error('getTimeEntries method is not available on the data provider');
        }
        
        const timeEntries = await dataProvider.getTimeEntries(issueId, projectId, userId, from, to, limit, offset);
        log.info(`Found ${timeEntries.length} time entries`);
        
        return timeEntries;
      } catch (error) {
        log.error(`Error in redmine_time_entries_list:`, error);
        throw new Error(`Failed to list time entries: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_get tool
  server.registerTool({
    name: "redmine_time_entry_get",
    description: "Get a specific time entry from Redmine",
    schema: z.object({
      time_entry_id: z.number().describe("Time entry ID")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { time_entry_id: number }) => {
      try {
        log.info(`Executing redmine_time_entry_get with params:`, params);
        
        const timeEntryId = params.time_entry_id;
        
        log.debug(`Fetching time entry: ${timeEntryId}`);
        
        // Check if getTimeEntry method exists on dataProvider
        if (!dataProvider.getTimeEntry) {
          throw new Error('getTimeEntry method is not available on the data provider');
        }
        
        const timeEntry = await dataProvider.getTimeEntry(timeEntryId);
        log.info(`Found time entry: ${timeEntry.id}`);
        
        return timeEntry;
      } catch (error) {
        log.error(`Error in redmine_time_entry_get:`, error);
        throw new Error(`Failed to get time entry: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_create tool
  server.registerTool({
    name: "redmine_time_entry_create",
    description: "Create a new time entry in Redmine",
    schema: z.object({
      issue_id: z.number().nullable().describe("Issue ID (either issue_id or project_id must be specified)"),
      project_id: z.number().nullable().describe("Project ID (either issue_id or project_id must be specified)"),
      hours: z.number().describe("Hours spent"),
      activity_id: z.number().describe("Activity ID"),
      spent_on: z.string().describe("Date when time was spent (YYYY-MM-DD)"),
      comments: z.string().optional().describe("Comments")
    }),
    // Fix: Add explicit type for params
    handler: async (params: {
      issue_id: number | null;
      project_id: number | null;
      hours: number;
      activity_id: number;
      spent_on: string;
      comments?: string;
    }) => {
      try {
        log.info(`Executing redmine_time_entry_create with params:`, params);
        
        const issueId = params.issue_id;
        const projectId = params.project_id;
        const hours = params.hours;
        const activityId = params.activity_id;
        const spentOn = params.spent_on;
        const comments = params.comments;
        
        // Validate parameters
        if (issueId === null && projectId === null) {
          throw new Error('Either issue_id or project_id must be specified');
        }
        
        if (hours <= 0) {
          throw new Error('Hours must be greater than 0');
        }
        
        log.debug(`Creating time entry for issue_id=${issueId || 'none'}, project_id=${projectId || 'none'}, hours=${hours}`);
        
        // Check if createTimeEntry method exists on dataProvider
        if (!dataProvider.createTimeEntry) {
          throw new Error('createTimeEntry method is not available on the data provider');
        }
        
        const timeEntry = await dataProvider.createTimeEntry(issueId, projectId, hours, activityId, spentOn, comments);
        log.info(`Created time entry: ${timeEntry.id}`);
        
        return timeEntry;
      } catch (error) {
        log.error(`Error in redmine_time_entry_create:`, error);
        throw new Error(`Failed to create time entry: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_update tool
  server.registerTool({
    name: "redmine_time_entry_update",
    description: "Update an existing time entry in Redmine",
    schema: z.object({
      time_entry_id: z.number().describe("Time entry ID"),
      hours: z.number().optional().describe("Hours spent"),
      activity_id: z.number().optional().describe("Activity ID"),
      spent_on: z.string().optional().describe("Date when time was spent (YYYY-MM-DD)"),
      comments: z.string().optional().describe("Comments")
    }),
    // Fix: Add explicit type for params
    handler: async (params: {
      time_entry_id: number;
      hours?: number;
      activity_id?: number;
      spent_on?: string;
      comments?: string;
    }) => {
      try {
        log.info(`Executing redmine_time_entry_update with params:`, params);
        
        const timeEntryId = params.time_entry_id;
        const hours = params.hours;
        const activityId = params.activity_id;
        const spentOn = params.spent_on;
        const comments = params.comments;
        
        log.debug(`Updating time entry: ${timeEntryId}`);
        
        // Check if updateTimeEntry method exists on dataProvider
        if (!dataProvider.updateTimeEntry) {
          throw new Error('updateTimeEntry method is not available on the data provider');
        }
        
        const success = await dataProvider.updateTimeEntry(timeEntryId, hours, activityId, spentOn, comments);
        
        if (success) {
          log.info(`Updated time entry: ${timeEntryId}`);
          return { success: true, message: `Time entry ${timeEntryId} updated successfully` };
        } else {
          log.warn(`Failed to update time entry: ${timeEntryId}`);
          return { success: false, message: `Failed to update time entry ${timeEntryId}` };
        }
      } catch (error) {
        log.error(`Error in redmine_time_entry_update:`, error);
        throw new Error(`Failed to update time entry: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_delete tool
  server.registerTool({
    name: "redmine_time_entry_delete",
    description: "Delete a time entry from Redmine",
    schema: z.object({
      time_entry_id: z.number().describe("Time entry ID")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { time_entry_id: number }) => {
      try {
        log.info(`Executing redmine_time_entry_delete with params:`, params);
        
        const timeEntryId = params.time_entry_id;
        
        log.debug(`Deleting time entry: ${timeEntryId}`);
        
        // Check if deleteTimeEntry method exists on dataProvider
        if (!dataProvider.deleteTimeEntry) {
          throw new Error('deleteTimeEntry method is not available on the data provider');
        }
        
        const success = await dataProvider.deleteTimeEntry(timeEntryId);
        
        if (success) {
          log.info(`Deleted time entry: ${timeEntryId}`);
          return { success: true, message: `Time entry ${timeEntryId} deleted successfully` };
        } else {
          log.warn(`Failed to delete time entry: ${timeEntryId}`);
          return { success: false, message: `Failed to delete time entry ${timeEntryId}` };
        }
      } catch (error) {
        log.error(`Error in redmine_time_entry_delete:`, error);
        throw new Error(`Failed to delete time entry: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_time_entry_activities tool
  server.registerTool({
    name: "redmine_time_entry_activities",
    description: "Get list of available time entry activities",
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
}
