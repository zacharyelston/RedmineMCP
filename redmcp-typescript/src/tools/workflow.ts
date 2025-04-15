/**
 * Workflow Tools for Redmine MCP
 * 
 * Provides tools for determining available status transitions based on current workflow
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Interface for workflow transition data
 */
interface WorkflowTransition {
  current_status_id: number;
  current_status_name: string;
  available_statuses: Array<{
    id: number;
    name: string;
  }>;
}

/**
 * Register workflow tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Redmine data provider
 * @param log - Logger instance
 */
export function registerWorkflowTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Get available status transitions for an issue
  server.tool(
    "redmine_workflow_get_next_statuses",
    {
      issue_id: z.number().describe('Issue ID'),
    },
    async ({ issue_id }: { issue_id: number }) => {
      log.debug(`Executing redmine_workflow_get_next_statuses (issue_id=${issue_id})`);
      
      try {
        // Check if issue_id is provided
        if (!issue_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Issue ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Get issue details to determine current status
        const issue = await dataProvider.getIssue(issue_id);
        
        if (!issue) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Issue not found", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Define the workflow transitions
        // This is a hardcoded mapping based on the workflow matrix shown in the UI
        // Ideally, this would be fetched from the API, but Redmine API doesn't expose workflows directly
        const workflowTransitions: Record<number, number[]> = {
          // Status ID 1 (New) can transition to:
          1: [1, 2], // New, In Progress
          
          // Status ID 2 (In Progress) can transition to:
          2: [2, 3], // In Progress, Feedback
          
          // Status ID 3 (Feedback) can transition to:
          3: [3, 4], // Feedback, Resolved
          
          // Status ID 4 (Resolved) can transition to:
          4: [4, 5], // Resolved, Closed
          
          // Status ID 5 (Closed) can transition to:
          5: [5], // Closed (only to itself)
          
          // Status ID 6 (Rejected) can transition to:
          6: [6] // Rejected (only to itself)
        };
        
        // Get available transitions for current status
        const currentStatusId = issue.status.id;
        const availableStatusIds = workflowTransitions[currentStatusId] || [];
        
        // Map of all status IDs to names
        const statusMap: Record<number, string> = {
          1: "New",
          2: "In Progress",
          3: "Feedback",
          4: "Resolved",
          5: "Closed",
          6: "Rejected"
        };
        
        // Create response with available transitions
        const response: WorkflowTransition = {
          current_status_id: currentStatusId,
          current_status_name: statusMap[currentStatusId] || issue.status.name,
          available_statuses: availableStatusIds.map(id => ({
            id,
            name: statusMap[id] || `Status ${id}`
          }))
        };
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              workflow: response,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_workflow_get_next_statuses: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get workflow transitions: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
}
