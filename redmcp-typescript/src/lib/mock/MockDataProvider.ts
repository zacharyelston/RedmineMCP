/**
 * MockDataProvider - Provides mock data for testing without a Redmine server
 */
import { DataProvider } from '../../client/index.js';

// Interface for mock issues to ensure type safety
interface MockIssue {
  id: number;
  project: { id: number; name: string };
  tracker: { id: number; name: string };
  status: { id: number; name: string };
  priority: { id: number; name: string };
  author: { id: number; name: string };
  assigned_to?: { id: number; name: string };
  subject: string;
  description: string;
  parent?: { id: number; subject: string };
  relations?: any[];
  children?: any[];
  created_on: string;
  updated_on: string;
}

// Mock projects
const mockProjects = [
  {
    id: 1,
    name: "Website Redesign",
    identifier: "website-redesign",
    description: "Project to redesign the company website",
    status: 1,
    created_on: "2025-03-01T10:00:00Z",
    updated_on: "2025-04-10T14:30:00Z"
  },
  {
    id: 2,
    name: "Mobile App Development",
    identifier: "mobile-app",
    description: "Development of native mobile applications",
    status: 1,
    created_on: "2025-02-15T09:00:00Z",
    updated_on: "2025-04-12T11:20:00Z"
  },
  {
    id: 3,
    name: "API Integration",
    identifier: "api-integration",
    description: "Integration with third-party APIs",
    status: 1,
    created_on: "2025-03-20T13:45:00Z",
    updated_on: "2025-04-05T16:10:00Z"
  }
];

// Mock issues
const mockIssues: MockIssue[] = [
  {
    id: 101,
    project: { id: 1, name: "Website Redesign" },
    tracker: { id: 1, name: "Bug" },
    status: { id: 1, name: "New" },
    priority: { id: 2, name: "Normal" },
    author: { id: 1, name: "John Doe" },
    assigned_to: { id: 2, name: "Jane Smith" },
    subject: "Header navigation broken on mobile",
    description: "The navigation menu in the header doesn't work properly on mobile devices.",
    created_on: "2025-04-01T09:30:00Z",
    updated_on: "2025-04-10T14:00:00Z"
  },
  {
    id: 102,
    project: { id: 1, name: "Website Redesign" },
    tracker: { id: 2, name: "Feature" },
    status: { id: 2, name: "In Progress" },
    priority: { id: 3, name: "High" },
    author: { id: 1, name: "John Doe" },
    assigned_to: { id: 3, name: "Bob Johnson" },
    subject: "Add dark mode support",
    description: "Implement dark mode support for better accessibility and user experience.",
    created_on: "2025-03-25T11:45:00Z",
    updated_on: "2025-04-08T10:20:00Z"
  },
  {
    id: 103,
    project: { id: 2, name: "Mobile App Development" },
    tracker: { id: 1, name: "Bug" },
    status: { id: 1, name: "New" },
    priority: { id: 4, name: "Urgent" },
    author: { id: 3, name: "Bob Johnson" },
    assigned_to: { id: 2, name: "Jane Smith" },
    subject: "App crashes on startup on Android 14",
    description: "The app crashes immediately after launch on devices running Android 14.",
    created_on: "2025-04-05T15:30:00Z",
    updated_on: "2025-04-05T15:30:00Z"
  },
  {
    id: 104,
    project: { id: 3, name: "API Integration" },
    tracker: { id: 3, name: "Support" },
    status: { id: 3, name: "Resolved" },
    priority: { id: 2, name: "Normal" },
    author: { id: 2, name: "Jane Smith" },
    assigned_to: { id: 1, name: "John Doe" },
    subject: "API authentication token expiration",
    description: "Need to implement automatic renewal of API authentication tokens.",
    created_on: "2025-03-28T09:15:00Z",
    updated_on: "2025-04-11T16:45:00Z"
  }
];

// Mock issue relations
const mockIssueRelations = [
  {
    id: 1,
    issue_id: 101,
    issue_to_id: 102,
    relation_type: "relates",
    delay: null
  },
  {
    id: 2,
    issue_id: 103,
    issue_to_id: 104,
    relation_type: "blocks",
    delay: null
  }
];

// Mock user
const mockCurrentUser = {
  id: 1,
  login: "john.doe",
  firstname: "John",
  lastname: "Doe",
  mail: "john.doe@example.com",
  created_on: "2025-01-15T08:00:00Z",
  last_login_on: "2025-04-14T08:30:00Z",
  api_key: "7a4ed5c91b405d30fda60909dbc86c2651c38217"
};

/**
 * Mock data provider class
 */
export class MockDataProvider implements DataProvider {
  /**
   * Get mock projects
   */
  async getProjects(limit: number = 25, offset: number = 0, sort: string = 'name:asc'): Promise<any[]> {
    // Clone the projects to avoid modifying the original data
    let projects = [...mockProjects];
    
    // Sort the projects if needed
    if (sort) {
      const [field, direction] = sort.split(':');
      projects.sort((a: any, b: any) => {
        if (direction === 'asc') {
          return a[field] > b[field] ? 1 : -1;
        } else {
          return a[field] < b[field] ? 1 : -1;
        }
      });
    }
    
    // Apply pagination
    return projects.slice(offset, offset + limit);
  }

  /**
   * Get a specific project by identifier
   */
  async getProject(identifier: string, includeData: string[] = []): Promise<any> {
    const project = mockProjects.find(p => p.identifier === identifier);
    if (!project) {
      throw new Error(`Project with identifier "${identifier}" not found`);
    }
    return project;
  }

  /**
   * Create a project (mock implementation)
   */
  async createProject(
    name: string,
    identifier: string,
    description?: string,
    isPublic: boolean = true,
    parentId?: number
  ): Promise<any> {
    return {
      id: mockProjects.length + 1,
      name,
      identifier,
      description: description || "",
      status: 1,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString(),
      parent: parentId ? { id: parentId, name: "Parent Project" } : undefined
    };
  }

  /**
   * Get mock issues
   */
  async getIssues(projectId?: string, statusId?: string, trackerId?: number, limit: number = 25, offset: number = 0, sort: string = 'updated_on:desc'): Promise<any[]> {
    // Clone the issues to avoid modifying the original data
    let issues = [...mockIssues];
    
    // Apply filters
    if (projectId) {
      const projectIdNum = Number(projectId);
      issues = issues.filter(issue => issue.project.id === projectIdNum);
    }
    
    if (statusId) {
      const statusIdNum = Number(statusId);
      issues = issues.filter(issue => issue.status.id === statusIdNum);
    }
    
    if (trackerId) {
      issues = issues.filter(issue => issue.tracker.id === trackerId);
    }
    
    // Sort the issues if needed
    if (sort) {
      const [field, direction] = sort.split(':');
      issues.sort((a: any, b: any) => {
        let aValue = a[field];
        let bValue = b[field];
        
        // Handle nested properties
        if (field.includes('.')) {
          const parts = field.split('.');
          aValue = parts.reduce((obj: any, part: string) => obj && obj[part], a);
          bValue = parts.reduce((obj: any, part: string) => obj && obj[part], b);
        }
        
        if (direction === 'asc') {
          return aValue > bValue ? 1 : -1;
        } else {
          return aValue < bValue ? 1 : -1;
        }
      });
    }
    
    // Apply pagination
    return issues.slice(offset, offset + limit);
  }

  /**
   * Get a specific issue by ID
   */
  async getIssue(issueId: number, includeData: string[] = []): Promise<any> {
    const issue = mockIssues.find(i => i.id === issueId);
    if (!issue) {
      throw new Error(`Issue with ID "${issueId}" not found`);
    }
    
    // Clone issue to avoid modifying the original
    const clonedIssue: MockIssue = { ...issue };
    
    // Add additional data if requested
    if (includeData.includes('relations')) {
      clonedIssue.relations = mockIssueRelations.filter(
        r => r.issue_id === issueId || r.issue_to_id === issueId
      );
    }
    
    if (includeData.includes('children')) {
      clonedIssue.children = mockIssues.filter(
        i => i.parent && i.parent.id === issueId
      );
    }
    
    return clonedIssue;
  }

  /**
   * Create a new issue (mock implementation)
   */
  async createIssue(
    projectId: number,
    subject: string,
    description?: string,
    trackerId?: number,
    statusId?: number,
    priorityId?: number,
    assignedToId?: number,
    parentIssueId?: number
  ): Promise<any> {
    // Find the highest issue ID to generate a new one
    const maxId = Math.max(...mockIssues.map(i => i.id));
    const newId = maxId + 1;
    
    // Find project
    const project = mockProjects.find(p => p.id === projectId);
    if (!project) {
      throw new Error(`Project with ID "${projectId}" not found`);
    }
    
    // Create parent reference if provided
    let parent = undefined;
    if (parentIssueId) {
      const parentIssue = mockIssues.find(i => i.id === parentIssueId);
      if (!parentIssue) {
        throw new Error(`Parent issue with ID "${parentIssueId}" not found`);
      }
      parent = { id: parentIssueId, subject: parentIssue.subject };
    }
    
    // Create new issue
    const newIssue: MockIssue = {
      id: newId,
      project: { id: projectId, name: project.name },
      tracker: { id: trackerId || 1, name: trackerId === 2 ? "Feature" : "Bug" },
      status: { id: statusId || 1, name: statusId === 2 ? "In Progress" : "New" },
      priority: { id: priorityId || 2, name: priorityId === 3 ? "High" : "Normal" },
      author: { id: 1, name: "John Doe" },
      assigned_to: assignedToId ? { id: assignedToId, name: "Jane Smith" } : undefined,
      subject,
      description: description || "",
      parent: parent,
      created_on: new Date().toISOString(),
      updated_on: new Date().toISOString()
    };
    
    // In a real implementation, we would add this to the database
    // For our mock, we'll just return it
    return newIssue;
  }

  /**
   * Update an existing issue (mock implementation)
   */
  async updateIssue(issueId: number, params: Record<string, any>): Promise<boolean> {
    // In a real implementation, we would update the issue in the database
    // For our mock, we'll just return success
    return true;
  }

  /**
   * Create a subtask (mock implementation)
   */
  async createSubtask(
    parentIssueId: number,
    subject: string,
    description?: string,
    trackerId?: number,
    statusId?: number,
    priorityId?: number
  ): Promise<any> {
    const parentIssue = mockIssues.find(i => i.id === parentIssueId);
    if (!parentIssue) {
      throw new Error(`Parent issue with ID "${parentIssueId}" not found`);
    }
    
    return this.createIssue(
      parentIssue.project.id,
      subject,
      description,
      trackerId,
      statusId,
      priorityId,
      undefined,
      parentIssueId
    );
  }

  /**
   * Set parent issue relationship (mock implementation)
   */
  async setParentIssue(issueId: number, parentIssueId: number): Promise<boolean> {
    return true;
  }

  /**
   * Remove parent issue relationship (mock implementation)
   */
  async removeParentIssue(issueId: number): Promise<boolean> {
    return true;
  }

  /**
   * Get child issues (mock implementation)
   */
  async getChildIssues(parentIssueId: number): Promise<any[]> {
    return mockIssues.filter(
      i => i.parent && i.parent.id === parentIssueId
    );
  }

  /**
   * Get issue relations (mock implementation)
   */
  async getIssueRelations(issueId: number): Promise<any[]> {
    return mockIssueRelations.filter(
      r => r.issue_id === issueId || r.issue_to_id === issueId
    );
  }

  /**
   * Create issue relation (mock implementation)
   */
  async createIssueRelation(
    issueId: number,
    targetIssueId: number,
    relationType: string,
    delay?: number
  ): Promise<any> {
    // Find the highest relation ID to generate a new one
    const maxId = mockIssueRelations.length > 0 ?
      Math.max(...mockIssueRelations.map(r => r.id)) : 0;
    const newId = maxId + 1;
    
    const newRelation = {
      id: newId,
      issue_id: issueId,
      issue_to_id: targetIssueId,
      relation_type: relationType,
      delay: delay || null
    };
    
    return newRelation;
  }

  /**
   * Delete issue relation (mock implementation)
   */
  async deleteIssueRelation(relationId: number): Promise<boolean> {
    return true;
  }

  /**
   * Add issue comment (mock implementation)
   */
  async addIssueComment(issueId: number, comment: string): Promise<boolean> {
    return true;
  }

  /**
   * Get current user information
   */
  async getCurrentUser(): Promise<any> {
    return mockCurrentUser;
  }

  /**
   * Test connection (always returns true for mock)
   */
  async testConnection(): Promise<boolean> {
    return true;
  }
}
