/**
 * Issue Relations MCP Tools
 * 
 * Contains tools for managing issue relations in Redmine
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';
import {
  GetIssueRelationsParams,
  CreateIssueRelationParams,
  DeleteIssueRelationParams,
  AddIssueCommentParams,
  SetParentIssueParams,
  RemoveParentIssueParams,
  GetChildIssuesParams,
  CreateSubtaskParams
} from '../types/issue-relations.js';

/**
 * Register issue relation tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Redmine data provider
 * @param log - Logger instance
 */
export function registerIssueRelationTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Get issue relations tool
  server.tool(
    "redmine_issue_relations_get",
    {
      issue_id: z.number().describe('Issue ID')
    },
    async ({ issue_id }: GetIssueRelationsParams) => {
      log.debug(`Executing redmine_issue_relations_get (issue_id=${issue_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.getIssueRelations) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
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
        
        // Convert to correct type
        const issueIdNum = Number(issue_id);
        
        // Get issue relations from the data provider
        const relations = await dataProvider.getIssueRelations(issueIdNum);
        
        // Return the issue relations
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              relations,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issue_relations_get: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get issue relations: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Create issue relation tool
  server.tool(
    "redmine_issue_relation_create",
    {
      issue_id: z.number().describe('Source issue ID'),
      target_issue_id: z.number().describe('Target issue ID'),
      relation_type: z.string().describe('Relation type (e.g., relates, duplicates, blocks, precedes)'),
      delay: z.number().optional().describe('Delay in days for precedes/follows relations')
    },
    async ({ issue_id, target_issue_id, relation_type, delay }: CreateIssueRelationParams) => {
      log.debug(`Executing redmine_issue_relation_create (issue_id=${issue_id}, target_issue_id=${target_issue_id}, relation_type=${relation_type})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.createIssueRelation) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
        // Validate parameters
        if (!issue_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Source issue ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        if (!target_issue_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Target issue ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        if (!relation_type) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Relation type is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Create issue relation
        const relation = await dataProvider.createIssueRelation(
          issue_id,
          target_issue_id,
          relation_type,
          delay
        );
        
        // Return the created relation
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              relation,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issue_relation_create: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to create issue relation: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Delete issue relation tool
  server.tool(
    "redmine_issue_relation_delete",
    {
      relation_id: z.number().describe('Relation ID')
    },
    async ({ relation_id }: DeleteIssueRelationParams) => {
      log.debug(`Executing redmine_issue_relation_delete (relation_id=${relation_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.deleteIssueRelation) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
        // Validate parameters
        if (!relation_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Relation ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Delete issue relation
        const success = await dataProvider.deleteIssueRelation(relation_id);
        
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
        log.error(`Error executing redmine_issue_relation_delete: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to delete issue relation: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Add issue comment tool
  server.tool(
    "redmine_issue_comment_add",
    {
      issue_id: z.number().describe('Issue ID'),
      comment: z.string().describe('Comment text')
    },
    async ({ issue_id, comment }: AddIssueCommentParams) => {
      log.debug(`Executing redmine_issue_comment_add (issue_id=${issue_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.addIssueComment) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
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
        
        if (!comment || comment.trim() === '') {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Comment text is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Add comment to issue
        const success = await dataProvider.addIssueComment(issue_id, comment);
        
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
        log.error(`Error executing redmine_issue_comment_add: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to add comment to issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Set parent issue tool
  server.tool(
    "redmine_issue_set_parent",
    {
      issue_id: z.number().describe('Issue ID to update'),
      parent_issue_id: z.number().describe('Parent issue ID')
    },
    async ({ issue_id, parent_issue_id }: SetParentIssueParams) => {
      log.debug(`Executing redmine_issue_set_parent (issue_id=${issue_id}, parent_issue_id=${parent_issue_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.setParentIssue) {
          // Try with updateIssue as fallback
          if (dataProvider.updateIssue) {
            const success = await dataProvider.updateIssue(issue_id, { parent_issue_id });
            return {
              content: [{ 
                type: "text", 
                text: JSON.stringify({ 
                  success,
                  status: "success"
                }, null, 2)
              }]
            };
          }
          
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
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
        
        if (!parent_issue_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Parent issue ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Set parent issue
        const success = await dataProvider.setParentIssue(issue_id, parent_issue_id);
        
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
        log.error(`Error executing redmine_issue_set_parent: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to set parent issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Remove parent issue tool
  server.tool(
    "redmine_issue_remove_parent",
    {
      issue_id: z.number().describe('Issue ID to update')
    },
    async ({ issue_id }: RemoveParentIssueParams) => {
      log.debug(`Executing redmine_issue_remove_parent (issue_id=${issue_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.removeParentIssue) {
          // Try with updateIssue as fallback
          if (dataProvider.updateIssue) {
            const success = await dataProvider.updateIssue(issue_id, { parent_issue_id: '' });
            return {
              content: [{ 
                type: "text", 
                text: JSON.stringify({ 
                  success,
                  status: "success"
                }, null, 2)
              }]
            };
          }
          
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
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
        
        // Remove parent issue
        const success = await dataProvider.removeParentIssue(issue_id);
        
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
        log.error(`Error executing redmine_issue_remove_parent: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to remove parent issue: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Get child issues tool
  server.tool(
    "redmine_issue_get_children",
    {
      parent_issue_id: z.number().describe('Parent issue ID')
    },
    async ({ parent_issue_id }: GetChildIssuesParams) => {
      log.debug(`Executing redmine_issue_get_children (parent_issue_id=${parent_issue_id})`);
      
      try {
        // Check if method exists in the data provider
        if (!dataProvider.getChildIssues) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
        
        // Validate parameters
        if (!parent_issue_id) {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Parent issue ID is required", 
                status: "error" 
              }, null, 2)
            }]
          };
        }
        
        // Get child issues
        const children = await dataProvider.getChildIssues(parent_issue_id);
        
        // Return the child issues
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              children,
              status: "success"
            }, null, 2)
          }]
        };
      } catch (error) {
        log.error(`Error executing redmine_issue_get_children: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to get child issues: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
  
  // Create subtask tool
  server.tool(
    "redmine_issue_create_subtask",
    {
      parent_issue_id: z.number().describe('Parent issue ID'),
      subject: z.string().describe('Subtask subject'),
      description: z.string().optional().describe('Subtask description'),
      tracker_id: z.number().optional().describe('Tracker ID'),
      status_id: z.number().optional().describe('Status ID'),
      priority_id: z.number().optional().describe('Priority ID')
    },
    async ({ parent_issue_id, subject, description, tracker_id, status_id, priority_id }: CreateSubtaskParams) => {
      log.debug(`Executing redmine_issue_create_subtask (parent_issue_id=${parent_issue_id}, subject=${subject})`);
      
      try {
        // Check if specific createSubtask method exists
        if (dataProvider.createSubtask) {
          // Create subtask using the specialized method
          const subtask = await dataProvider.createSubtask(
            parent_issue_id,
            subject,
            description,
            tracker_id,
            status_id,
            priority_id
          );
          
          // Return the created subtask
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                subtask,
                status: "success"
              }, null, 2)
            }]
          };
        } else if (dataProvider.createIssue) {
          // If no specialized method exists, try to get the parent issue first
          const parentIssue = await dataProvider.getIssue(parent_issue_id);
          
          // Create subtask using the general createIssue method
          const subtask = await dataProvider.createIssue(
            parentIssue.project.id,
            subject,
            description,
            tracker_id,
            status_id,
            priority_id,
            undefined, // No assignee
            parent_issue_id // Specify parent issue ID
          );
          
          // Return the created subtask
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                subtask,
                status: "success"
              }, null, 2)
            }]
          };
        } else {
          return {
            content: [{ 
              type: "text", 
              text: JSON.stringify({ 
                error: "Operation not supported by the current data provider",
                status: "error"
              }, null, 2)
            }]
          };
        }
      } catch (error) {
        log.error(`Error executing redmine_issue_create_subtask: ${(error as Error).message}`);
        
        return {
          content: [{ 
            type: "text", 
            text: JSON.stringify({ 
              error: `Failed to create subtask: ${(error as Error).message}`,
              status: "error"
            }, null, 2)
          }]
        };
      }
    }
  );
}
