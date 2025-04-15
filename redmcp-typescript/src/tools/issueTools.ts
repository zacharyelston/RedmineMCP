/**
 * Issue MCP Tools
 * 
 * Contains tools for managing issues in Redmine
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register issue tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Redmine data provider
 * @param log - Logger instance
 */
export function registerIssueTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Get issues tool
  server.tool(
    "redmine_issues_list",
    {
      project_id: z.string().optional().describe('Filter by project identifier'),
      status_id: z.string().optional().describe('Filter by status'),
      tracker_id: z.number().optional().describe('Filter by tracker'),
      limit: z.number().optional().default(25).describe('Number of issues to return (default: 25)'),
      offset: z.number().optional().default(0).describe('Pagination offset (default: 0)'),
      sort: z.string().optional().default('updated_on:desc').describe('Field to sort by with direction (default: updated_on:desc)')
    },
    async ({ project_id, status_id, tracker_id, limit, offset, sort }) => {
      log.debug(`Executing redmine_issues_list (project_id=${project_id || 'all'}, limit=${limit}, offset=${offset})`);
      
      try {
        // Get issues from the data provider
        const issues = await dataProvider.getIssues(
          project_id,
          status_id,
          tracker_id,
          limit,
          offset,
          sort
        );
        
        // Return the issues
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              issues,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issues_list: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get issues: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Get issue tool
  server.tool(
    "redmine_issues_get",
    {
      issue_id: z.number().describe('Issue ID'),
      include: z.array(z.string()).optional().default([]).describe('Related data to include')
    },
    async ({ issue_id, include }) => {
      log.debug(`Executing redmine_issues_get (issue_id=${issue_id})`);
      
      try {
        // Validate parameters
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
        
        // Get issue from the data provider
        const issue = await dataProvider.getIssue(issue_id, include);
        
        // Return the issue
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              issue,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issues_get: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Create issue tool with parent-child support
  server.tool(
    "redmine_issues_create",
    {
      project_id: z.number().describe('Project ID'),
      subject: z.string().describe('Issue subject'),
      description: z.string().optional().describe('Issue description'),
      tracker_id: z.number().optional().describe('Tracker ID'),
      status_id: z.number().optional().describe('Status ID'),
      priority_id: z.number().optional().describe('Priority ID'),
      assigned_to_id: z.number().optional().describe('Assignee ID'),
      parent_issue_id: z.number().optional().describe('Parent issue ID to create a subtask')
    },
    async ({ project_id, subject, description, tracker_id, status_id, priority_id, assigned_to_id, parent_issue_id }) => {
      log.debug(`Executing redmine_issues_create (project_id=${project_id}, subject=${subject})`);
      if (parent_issue_id) {
        log.debug(`Creating subtask of issue ${parent_issue_id}`);
      }
      
      try {
        // Validate parameters
        if (!project_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Project ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        if (!subject || subject.trim() === '') {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Subject is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Validate parent issue if provided
        if (parent_issue_id) {
          try {
            const parentIssue = await dataProvider.getIssue(parent_issue_id);
            log.debug(`Parent issue verified: ${parentIssue.subject} (ID: ${parentIssue.id})`);
          } catch (parentError) {
            return {
              content: [{ 
                type: "text", 
                text: JSON.stringify({ 
                  error: `Parent issue with ID ${parent_issue_id} could not be found or accessed: ${(parentError as Error).message}`,
                  status: "error" 
                }, null, 2)
              }]
            };
          }
        }
        
        // Convert parameter types
        const projectIdNum = Number(project_id);
        const trackerIdNum = tracker_id !== undefined ? Number(tracker_id) : undefined;
        const statusIdNum = status_id !== undefined ? Number(status_id) : undefined;
        const priorityIdNum = priority_id !== undefined ? Number(priority_id) : undefined;
        const assignedToIdNum = assigned_to_id !== undefined ? Number(assigned_to_id) : undefined;
        const parentIssueIdNum = parent_issue_id !== undefined ? Number(parent_issue_id) : undefined;
        
        // Create issue
        const issue = await dataProvider.createIssue(
          projectIdNum,
          subject,
          description,
          trackerIdNum,
          statusIdNum,
          priorityIdNum,
          assignedToIdNum,
          parentIssueIdNum
        );
        
        // Verify parent-child relationship if needed
        if (parent_issue_id && (!issue.parent || issue.parent.id !== parent_issue_id)) {
          log.warn(`Issue created but parent-child relationship may not be correctly established`);
        }
        
        // Return the created issue
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              issue,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issues_create: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to create issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Update issue tool
  server.tool(
    "redmine_issues_update",
    {
      issue_id: z.number().describe('Issue ID'),
      subject: z.string().optional().describe('New issue subject'),
      description: z.string().optional().describe('New issue description'),
      status_id: z.number().optional().describe('New status ID'),
      priority_id: z.number().optional().describe('New priority ID'),
      assigned_to_id: z.number().optional().describe('New assignee ID'),
      parent_issue_id: z.number().optional().describe('Parent issue ID')
    },
    async ({ issue_id, subject, description, status_id, priority_id, assigned_to_id, parent_issue_id }) => {
      log.debug(`Executing redmine_issues_update (issue_id=${issue_id})`);
      
      try {
        // Validate parameters
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
        
        // Create parameters object
        const params: Record<string, any> = {};
        
        if (subject !== undefined) params.subject = subject;
        if (description !== undefined) params.description = description;
        if (status_id !== undefined) params.status_id = status_id;
        if (priority_id !== undefined) params.priority_id = priority_id;
        if (assigned_to_id !== undefined) params.assigned_to_id = assigned_to_id;
        if (parent_issue_id !== undefined) params.parent_issue_id = parent_issue_id;
        
        // Validate parent issue if provided
        if (parent_issue_id) {
          try {
            const parentIssue = await dataProvider.getIssue(parent_issue_id);
            log.debug(`Parent issue verified: ${parentIssue.subject} (ID: ${parentIssue.id})`);
          } catch (parentError) {
            return {
              content: [{ 
                type: "text", 
                text: JSON.stringify({ 
                  error: `Parent issue with ID ${parent_issue_id} could not be found or accessed: ${(parentError as Error).message}`,
                  status: "error" 
                }, null, 2)
              }]
            };
          }
        }
        
        // Update issue
        const success = await dataProvider.updateIssue(issue_id, params);
        
        // Return result
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              success,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issues_update: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to update issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Get current user tool
  server.tool(
    "redmine_users_current",
    {},
    async () => {
      log.debug('Executing redmine_users_current');
      
      try {
        // Get current user from the data provider
        const user = await dataProvider.getCurrentUser();
        
        // Return the user
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              user,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_users_current: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get current user: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
}
