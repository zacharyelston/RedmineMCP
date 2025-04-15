/**
 * MCP Tools Module Index
 * Exports all tool registration functions
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { DataProvider } from '../client/index.js';
import { registerIssueRelationTools } from './issueRelations.js';
import { registerIssueTools } from './issueTools.js';
import { registerProjectTools } from './projects.js';
import { registerWikiTools } from './wiki.js';
import { registerTimeTools } from './time.js';
import { registerAttachmentTools } from './attachments.js';
import { registerMetadataTools } from './metadata.js';
import { registerWorkflowTools } from './workflow.js';

/**
 * Register all MCP tools with the server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerAllTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register project tools
  registerProjectTools(server, dataProvider, log);
  
  // Register issue tools
  registerIssueTools(server, dataProvider, log);
  
  // Register issue relation tools
  registerIssueRelationTools(server, dataProvider, log);
  
  // Register wiki tools
  registerWikiTools(server, dataProvider, log);
  
  // Register time tracking tools
  registerTimeTools(server, dataProvider, log);
  
  // Register attachment tools
  registerAttachmentTools(server, dataProvider, log);
  
  // Register metadata tools
  registerMetadataTools(server, dataProvider, log);
  
  // Register workflow tools
  registerWorkflowTools(server, dataProvider, log);
  
  // Log registration complete
  log.info('All MCP tools registered successfully');
}

export { 
  registerProjectTools,
  registerIssueTools, 
  registerIssueRelationTools,
  registerWikiTools,
  registerTimeTools,
  registerAttachmentTools,
  registerMetadataTools,
  registerWorkflowTools
};
