/**
 * Core types and interfaces for Redmine MCP
 */

// Error log entry interface
export interface ErrorLogEntry {
  timestamp: string;
  level: 'critical' | 'error' | 'warning' | 'info';
  component: string;
  operation: string;
  error_message: string;
  stack_trace?: string;
  context?: Record<string, any>;
  action?: string;
}

// Logger interface
export interface Logger {
  info: (...args: any[]) => void;
  error: (...args: any[]) => void;
  debug: (...args: any[]) => void;
  warn: (...args: any[]) => void;
}

// Data provider interface for Redmine API
export interface DataProvider {
  // Project methods
  createProject?(name: string, identifier: string, description?: string, isPublic?: boolean, parentId?: number): Promise<any>;
  getProjects(limit?: number, offset?: number, sort?: string): Promise<any[]>;
  getProject(identifier: string, includeData?: string[]): Promise<any>;
  
  // Issue methods
  getIssues(projectId?: string, statusId?: string, trackerId?: number, limit?: number, offset?: number, sort?: string): Promise<any[]>;
  getIssue(issueId: number, includeData?: string[]): Promise<any>;
  createIssue(projectId: number, subject: string, description?: string, trackerId?: number, statusId?: number, priorityId?: number, assignedToId?: number, parentIssueId?: number): Promise<any>;
  updateIssue(issueId: number, params: Record<string, any>): Promise<boolean>;
  
  // Parent/Child relations
  createSubtask?(parentIssueId: number, subject: string, description?: string, trackerId?: number, statusId?: number, priorityId?: number): Promise<any>;
  setParentIssue?(issueId: number, parentIssueId: number): Promise<boolean>;
  removeParentIssue?(issueId: number): Promise<boolean>;
  getChildIssues?(parentIssueId: number): Promise<any[]>;
  
  // Issue relations
  getIssueRelations?(issueId: number): Promise<any[]>;
  createIssueRelation?(issueId: number, targetIssueId: number, relationType: string, delay?: number): Promise<any>;
  deleteIssueRelation?(relationId: number): Promise<boolean>;
  
  // Issue comments
  addIssueComment?(issueId: number, comment: string): Promise<boolean>;
  
  // User methods
  getCurrentUser(): Promise<any>;
  
  // Connection test
  testConnection(): Promise<boolean>;
}

// MCP Tool definition type
export interface McpTool {
  name: string;
  description: string;
  schema: any;
  handler: (params: any) => Promise<any>;
}
