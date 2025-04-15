/**
 * Wiki Tools Module
 * Provides MCP tools for interacting with Redmine wiki pages
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register wiki-related tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerWikiTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register redmine_wiki_pages_list tool
  server.registerTool({
    name: "redmine_wiki_pages_list",
    description: "List all wiki pages in a Redmine project",
    schema: z.object({
      project_id: z.string().describe("Project identifier")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id: string }) => {
      try {
        log.info(`Executing redmine_wiki_pages_list with params:`, params);
        
        const projectId = params.project_id;
        
        log.debug(`Fetching wiki pages for project: ${projectId}`);
        
        // Check if getWikiPages method exists on dataProvider
        if (!dataProvider.getWikiPages) {
          throw new Error('getWikiPages method is not available on the data provider');
        }
        
        const wikiPages = await dataProvider.getWikiPages(projectId);
        log.info(`Found ${wikiPages.length} wiki pages for project ${projectId}`);
        
        return wikiPages;
      } catch (error) {
        log.error(`Error in redmine_wiki_pages_list:`, error);
        throw new Error(`Failed to list wiki pages: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_wiki_page_get tool
  server.registerTool({
    name: "redmine_wiki_page_get",
    description: "Get a specific wiki page from a Redmine project",
    schema: z.object({
      project_id: z.string().describe("Project identifier"),
      page_title: z.string().describe("Wiki page title"),
      version: z.number().optional().describe("Wiki page version")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id: string; page_title: string; version?: number }) => {
      try {
        log.info(`Executing redmine_wiki_page_get with params:`, params);
        
        const projectId = params.project_id;
        const pageTitle = params.page_title;
        const version = params.version;
        
        log.debug(`Fetching wiki page "${pageTitle}" for project: ${projectId}${version ? `, version: ${version}` : ''}`);
        
        // Check if getWikiPage method exists on dataProvider
        if (!dataProvider.getWikiPage) {
          throw new Error('getWikiPage method is not available on the data provider');
        }
        
        const wikiPage = await dataProvider.getWikiPage(projectId, pageTitle, version);
        log.info(`Found wiki page: ${wikiPage.title}`);
        
        return wikiPage;
      } catch (error) {
        log.error(`Error in redmine_wiki_page_get:`, error);
        throw new Error(`Failed to get wiki page: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_wiki_page_create_or_update tool
  server.registerTool({
    name: "redmine_wiki_page_create_or_update",
    description: "Create or update a wiki page in a Redmine project",
    schema: z.object({
      project_id: z.string().describe("Project identifier"),
      page_title: z.string().describe("Wiki page title"),
      content: z.string().describe("Wiki page content"),
      comments: z.string().optional().describe("Comments about the update")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { 
      project_id: string; 
      page_title: string; 
      content: string;
      comments?: string;
    }) => {
      try {
        log.info(`Executing redmine_wiki_page_create_or_update with params:`, params);
        
        const projectId = params.project_id;
        const pageTitle = params.page_title;
        const content = params.content;
        const comments = params.comments;
        
        log.debug(`Creating/updating wiki page "${pageTitle}" for project: ${projectId}`);
        
        // Check if createOrUpdateWikiPage method exists on dataProvider
        if (!dataProvider.createOrUpdateWikiPage) {
          throw new Error('createOrUpdateWikiPage method is not available on the data provider');
        }
        
        const wikiPage = await dataProvider.createOrUpdateWikiPage(projectId, pageTitle, content, comments);
        log.info(`Created/updated wiki page: ${wikiPage.title}`);
        
        return wikiPage;
      } catch (error) {
        log.error(`Error in redmine_wiki_page_create_or_update:`, error);
        throw new Error(`Failed to create/update wiki page: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_wiki_page_delete tool
  server.registerTool({
    name: "redmine_wiki_page_delete",
    description: "Delete a wiki page from a Redmine project",
    schema: z.object({
      project_id: z.string().describe("Project identifier"),
      page_title: z.string().describe("Wiki page title")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id: string; page_title: string }) => {
      try {
        log.info(`Executing redmine_wiki_page_delete with params:`, params);
        
        const projectId = params.project_id;
        const pageTitle = params.page_title;
        
        log.debug(`Deleting wiki page "${pageTitle}" for project: ${projectId}`);
        
        // Check if deleteWikiPage method exists on dataProvider
        if (!dataProvider.deleteWikiPage) {
          throw new Error('deleteWikiPage method is not available on the data provider');
        }
        
        const success = await dataProvider.deleteWikiPage(projectId, pageTitle);
        
        if (success) {
          log.info(`Deleted wiki page: ${pageTitle}`);
          return { success: true, message: `Wiki page "${pageTitle}" deleted successfully` };
        } else {
          log.warn(`Failed to delete wiki page: ${pageTitle}`);
          return { success: false, message: `Failed to delete wiki page "${pageTitle}"` };
        }
      } catch (error) {
        log.error(`Error in redmine_wiki_page_delete:`, error);
        throw new Error(`Failed to delete wiki page: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_wiki_page_history tool
  server.registerTool({
    name: "redmine_wiki_page_history",
    description: "Get the history of a wiki page from a Redmine project",
    schema: z.object({
      project_id: z.string().describe("Project identifier"),
      page_title: z.string().describe("Wiki page title")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { project_id: string; page_title: string }) => {
      try {
        log.info(`Executing redmine_wiki_page_history with params:`, params);
        
        const projectId = params.project_id;
        const pageTitle = params.page_title;
        
        log.debug(`Fetching history for wiki page "${pageTitle}" for project: ${projectId}`);
        
        // Check if getWikiPageHistory method exists on dataProvider
        if (!dataProvider.getWikiPageHistory) {
          throw new Error('getWikiPageHistory method is not available on the data provider');
        }
        
        const history = await dataProvider.getWikiPageHistory(projectId, pageTitle);
        log.info(`Found ${history.length} versions for wiki page "${pageTitle}"`);
        
        return history;
      } catch (error) {
        log.error(`Error in redmine_wiki_page_history:`, error);
        throw new Error(`Failed to get wiki page history: ${(error as Error).message}`);
      }
    }
  });
}
