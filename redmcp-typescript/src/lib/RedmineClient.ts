/**
 * RedmineClient - A client for interacting with Redmine API
 * 
 * FIXED VERSION FOR ISSUE #76 - Subproject Creation Failure
 */
import axios, { AxiosInstance } from 'axios';
import * as fs from 'fs';
import * as path from 'path';

// Interface for error log entry
interface ErrorLogEntry {
  timestamp: string;
  level: 'critical' | 'error' | 'warning' | 'info';
  component: string;
  operation: string;
  error_message: string;
  stack_trace?: string;
  context?: Record<string, any>;
  action?: string;
}

export class RedmineClient {
  private api: AxiosInstance;
  private baseUrl: string;
  private apiKey: string;
  private todoFilePath: string;

  /**
   * Create a new Redmine API client
   * @param baseUrl - The base URL of the Redmine instance
   * @param apiKey - API key for authentication
   * @param todoFilePath - Path to the todo.yaml file for error logging
   */
  constructor(baseUrl: string, apiKey: string, todoFilePath: string = '../../todo.yaml') {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.todoFilePath = path.resolve(__dirname, todoFilePath);

    // Create axios instance with default configuration
    this.api = axios.create({
      baseURL: baseUrl,
      headers: {
        'X-Redmine-API-Key': apiKey,
        'Content-Type': 'application/json',
        // Accept multiple formats including XML
        'Accept': 'application/json, application/xml, text/xml, */*'
      }
    });

    // Add logging interceptor
    this.api.interceptors.request.use(config => {
      // Ensure params object exists
      if (!config.params) {
        config.params = {};
      }
      // Add format=json parameter to all requests
      config.params.format = 'json';
      
      console.error(`Making ${config.method?.toUpperCase()} request to ${config.url}`);
      return config;
    });

    console.error(`Initialized Redmine client for ${baseUrl}`);
  }

  /**
   * Log error to the todo.yaml file
   * @param errorInfo - Error information to log
   */
  private async logError(errorInfo: ErrorLogEntry): Promise<void> {
    try {
      // Create error log entry
      const errorEntry = {
        timestamp: errorInfo.timestamp,
        level: errorInfo.level,
        component: errorInfo.component,
        operation: errorInfo.operation,
        error_message: errorInfo.error_message,
        stack_trace: errorInfo.stack_trace || '',
        context: errorInfo.context || {},
        action: errorInfo.action || 'Investigate and fix the issue'
      };

      // Read current todo.yaml
      let todoData: any = {};
      try {
        if (fs.existsSync(this.todoFilePath)) {
          const todoContent = fs.readFileSync(this.todoFilePath, 'utf8');
          todoData = JSON.parse(todoContent);
        } else {
          todoData = {
            version: "1.0.0",
            updated: new Date().toISOString(),
            tasks: [],
            errors: []
          };
        }
      } catch (readError) {
        // If JSON parsing fails, create a new structure
        todoData = {
          version: "1.0.0",
          updated: new Date().toISOString(),
          tasks: [],
          errors: []
        };
      }

      // Add error entry
      if (!todoData.errors) {
        todoData.errors = [];
      }
      todoData.errors.push(errorEntry);
      todoData.updated = new Date().toISOString();

      // Write back to file
      fs.writeFileSync(this.todoFilePath, JSON.stringify(todoData, null, 2), 'utf8');
      console.error(`Error logged to ${this.todoFilePath}`);
    } catch (logError) {
      console.error('Failed to log error to todo.yaml:', logError);
    }
  }

  /**
   * Create a new Redmine project
   * @param name - Project name
   * @param identifier - Project identifier (slug)
   * @param description - Project description
   * @param isPublic - Whether the project is public
   * @param parentId - ID of parent project for subproject creation
   * @returns Created project
   */
  async createProject(
    name: string,
    identifier: string,
    description?: string,
    isPublic: boolean = true,
    parentId?: number
  ) {
    console.error(`Creating project: "${name}", identifier: "${identifier}"`);
    console.error(`Parameters: parentId=${parentId || 'none'}, isPublic=${isPublic}, description=${description ? "provided" : "undefined"}`);
    
    // Parameter validation
    if (!name || name.trim() === '') {
      const errorMessage = 'Project name is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createProject',
        error_message: errorMessage,
        context: { name, identifier, parentId }
      });
      
      throw new Error(errorMessage);
    }
    
    if (!identifier || identifier.trim() === '') {
      const errorMessage = 'Project identifier is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createProject',
        error_message: errorMessage,
        context: { name, identifier, parentId }
      });
      
      throw new Error(errorMessage);
    }
    
    // Create properly structured data object
    const data: Record<string, any> = {
      project: {
        name: name.trim(),
        identifier: identifier.trim(),
        is_public: isPublic
      }
    };
    
    // Add optional parameters if specified
    if (description !== undefined && description !== null) {
      data.project.description = description;
    }
    
    // Add parent project ID if specified (for subproject creation)
    if (parentId !== undefined && parentId !== null) {
      // Ensure parent_id is converted to a number - FIX: explicit Number conversion
      data.project.parent_id = Number(parentId);
      
      // Log the exact parent_id being sent for debugging - FIX: added for debugging
      console.error(`Setting parent_id: ${data.project.parent_id} (${typeof data.project.parent_id})`);
      
      // FIX: Verify parent project exists before attempting to create subproject
      try {
        // Attempt to get the parent project to verify it exists
        const parentProject = await this.getProject(`id:${parentId}`);
        console.error(`Parent project verified: ${parentProject.name} (ID: ${parentProject.id})`);
      } catch (parentError) {
        const errorMessage = `Parent project with ID ${parentId} could not be found or accessed`;
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'RedmineClient',
          operation: 'createProject',
          error_message: errorMessage,
          context: { name, identifier, parentId }
        });
        
        throw new Error(errorMessage);
      }
    }
    
    // Log the exact payload being sent (for debugging)
    console.error(`Request payload: ${JSON.stringify(data, null, 2)}`);
    
    try {
      // FIX: Make the request with explicit headers
      const response = await this.api.post('/projects.json', data, {
        headers: {
          'X-Redmine-API-Key': this.apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });
      
      console.error(`Response status: ${response.status}`);
      console.error(`Response data: ${JSON.stringify(response.data, null, 2)}`);
      
      if (!response.data || !response.data.project) {
        const errorMessage = 'Unexpected response format from Redmine API';
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'RedmineClient',
          operation: 'createProject',
          error_message: errorMessage,
          context: { 
            name, 
            identifier, 
            parentId,
            response: response.data 
          }
        });
        
        throw new Error(errorMessage);
      }
      
      // FIX: Verify project creation - especially important for subprojects
      try {
        // FIX: Wait longer (3 seconds) for parent project association to be established in database
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Fetch the project to confirm it exists
        const createdProject = await this.getProject(identifier);
        
        // FIX: Enhanced verification for parent_id
        if (parentId && (!createdProject.parent || createdProject.parent.id !== parentId)) {
          const errorMessage = `Project created but not properly associated with parent ID ${parentId}`;
          console.error(`Error: ${errorMessage}`);
          
          // FIX: Try to get the parent project details to verify it exists
          try {
            const parentProject = await this.getProject(`id:${parentId}`);
            console.error(`Parent project exists: ${parentProject.name}`);
          } catch (parentError) {
            console.error(`Error fetching parent project: ${(parentError as Error).message}`);
          }
          
          // Log error to todo.yaml
          await this.logError({
            timestamp: new Date().toISOString(),
            level: 'warning',
            component: 'RedmineClient',
            operation: 'createProject',
            error_message: errorMessage,
            context: { 
              name, 
              identifier, 
              expectedParentId: parentId,
              createdProject 
            },
            action: 'Project may need to be manually moved to correct parent'
          });
          
          // FIX: Create an error issue in the bugs project
          try {
            await this.createIssue(
              5, // bugs project ID
              `Subproject Association Failed: ${name}`,
              `
## Automated Error Report

A project was created but failed to associate with its parent project.

**Project Name:** ${name}
**Project Identifier:** ${identifier}
**Expected Parent ID:** ${parentId}
**Created Project ID:** ${createdProject.id}

### Details

The project was successfully created in Redmine but the parent-child relationship was not established correctly. The project may need to be manually moved to the correct parent.
              `,
              1, // Bug tracker ID
              1, // New status ID
              3  // High priority ID
            );
          } catch (issueError) {
            console.error(`Failed to create error issue: ${(issueError as Error).message}`);
          }
        }
        
        return createdProject;
      } catch (verifyError) {
        // Project was created but verification failed
        console.error(`Warning: Project created but verification failed:`, verifyError);
        
        // Log warning to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'warning',
          component: 'RedmineClient',
          operation: 'createProject',
          error_message: `Project created but verification failed: ${(verifyError as Error).message}`,
          context: { 
            name, 
            identifier, 
            parentId,
            createdProjectId: response.data.project.id 
          },
          action: 'Verify project was created correctly'
        });
        
        // Return the project data anyway since it was created
        return response.data.project;
      }
    } catch (error) {
      console.error('Error creating project:', error);
      
      // Enhanced error reporting with detailed information
      let errorMessage = `Failed to create Redmine project: ${(error as Error).message}`;
      let errorDetails = {};
      
      if (axios.isAxiosError(error)) {
        if (error.response) {
          console.error(`Status: ${error.response.status}`);
          console.error(`Response headers: ${JSON.stringify(error.response.headers, null, 2)}`);
          console.error(`Response data: ${JSON.stringify(error.response.data, null, 2)}`);
          
          // Extract specific error messages if available
          const axiosErrorDetails = error.response.data?.errors || [];
          if (axiosErrorDetails.length > 0) {
            console.error(`Specific errors: ${JSON.stringify(axiosErrorDetails, null, 2)}`);
            
            // FIX: Check for parent_id related errors
            const parentIdErrors = axiosErrorDetails.filter((e: any) => 
              typeof e === 'string' && e.toLowerCase().includes('parent'));
            
            if (parentIdErrors.length > 0) {
              errorMessage = `Failed to create subproject: ${parentIdErrors.join(', ')}`;
              errorDetails = { parent_errors: parentIdErrors };
            } else {
              errorMessage = `Failed to create Redmine project: ${axiosErrorDetails.join(', ')}`;
              errorDetails = { errors: axiosErrorDetails };
            }
          }
        } else if (error.request) {
          console.error('Error: No response received from server');
          console.error(`Request details: ${JSON.stringify(error.request, null, 2)}`);
          errorDetails = { request: 'No response received from server' };
        } else {
          console.error(`Error setting up request: ${error.message}`);
          errorDetails = { setup: error.message };
        }
        
        // Include request details in error message
        console.error(`Request config: ${JSON.stringify(error.config, null, 2)}`);
      }
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createProject',
        error_message: errorMessage,
        stack_trace: (error as Error).stack,
        context: { 
          name, 
          identifier, 
          parentId,
          request: data,
          errorDetails
        }
      });
      
      // FIX: Create an error issue for the failure
      try {
        await this.createIssue(
          5, // bugs project ID
          `Project Creation Failed: ${name}`,
          `
## Automated Error Report

Failed to create project in Redmine.

**Project Name:** ${name}
**Project Identifier:** ${identifier}
**Parent ID:** ${parentId || 'None'}

### Error Details
\`\`\`
${errorMessage}
\`\`\`

### Request Data
\`\`\`json
${JSON.stringify(data, null, 2)}
\`\`\`

### Error Details
\`\`\`json
${JSON.stringify(errorDetails, null, 2)}
\`\`\`
          `,
          1, // Bug tracker ID
          1, // New status ID
          3  // High priority ID
        );
      } catch (issueError) {
        console.error(`Failed to create error issue: ${(issueError as Error).message}`);
      }
      
      throw new Error(errorMessage);
    }
  }

  /**
   * Get a list of projects
   * @param limit - Maximum number of projects to return
   * @param offset - Pagination offset
   * @param sort - Sort field and direction (field:direction)
   * @returns List of projects
   */
  async getProjects(limit: number = 25, offset: number = 0, sort: string = 'name:asc') {
    console.error(`Fetching projects (limit: ${limit}, offset: ${offset})`);
    
    const params: Record<string, any> = {
      limit,
      offset
    };
    
    // Parse sort parameter (field:direction)
    if (sort && sort.includes(':')) {
      const [field, direction] = sort.split(':');
      params.sort = field;
      params.order = direction;
    }
    
    try {
      const response = await this.api.get('/projects.json', { params });
      return response.data.projects;
    } catch (error) {
      console.error('Error fetching projects:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'getProjects',
        error_message: `Failed to fetch Redmine projects: ${(error as Error).message}`,
        context: { limit, offset, sort }
      });
      
      throw new Error(`Failed to fetch Redmine projects: ${(error as Error).message}`);
    }
  }

  /**
   * Get a specific project by identifier
   * @param identifier - Project identifier
   * @param includeData - Additional data to include
   * @returns Project details
   */
  async getProject(identifier: string, includeData: string[] = []) {
    console.error(`Fetching project: ${identifier}`);
    
    const params: Record<string, any> = {};
    
    // Add include parameter if specified
    if (includeData.length > 0) {
      params.include = includeData.join(',');
    }
    
    try {
      const response = await this.api.get(`/projects/${identifier}.json`, { params });
      return response.data.project;
    } catch (error) {
      console.error(`Error fetching project ${identifier}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'getProject',
        error_message: `Failed to fetch Redmine project: ${(error as Error).message}`,
        context: { identifier, includeData }
      });
      
      throw new Error(`Failed to fetch Redmine project: ${(error as Error).message}`);
    }
  }

  /**
   * Get a list of issues
   * @param projectId - Optional project identifier to filter issues
   * @param statusId - Optional status ID to filter issues
   * @param trackerId - Optional tracker ID to filter issues
   * @param limit - Maximum number of issues to return
   * @param offset - Pagination offset
   * @param sort - Sort field and direction (field:direction)
   * @returns List of issues
   */
  async getIssues(projectId?: string, statusId?: string, trackerId?: number, limit: number = 25, offset: number = 0, sort: string = 'updated_on:desc') {
    console.error(`Fetching issues (project: ${projectId || 'all'}, limit: ${limit}, offset: ${offset})`);
    
    const params: Record<string, any> = {
      limit,
      offset
    };
    
    // Add filters if specified
    if (projectId) params.project_id = projectId;
    if (statusId) params.status_id = statusId;
    if (trackerId) params.tracker_id = trackerId;
    
    // Parse sort parameter (field:direction)
    if (sort && sort.includes(':')) {
      const [field, direction] = sort.split(':');
      params.sort = field;
      params.order = direction;
    }
    
    try {
      // Choose endpoint based on whether project ID is specified
      const endpoint = projectId ? `/projects/${projectId}/issues.json` : '/issues.json';
      const response = await this.api.get(endpoint, { params });
      return response.data.issues;
    } catch (error) {
      console.error('Error fetching issues:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'getIssues',
        error_message: `Failed to fetch Redmine issues: ${(error as Error).message}`,
        context: { projectId, statusId, trackerId, limit, offset, sort }
      });
      
      throw new Error(`Failed to fetch Redmine issues: ${(error as Error).message}`);
    }
  }
  
  /**
   * Get a specific issue by ID
   * @param issueId - Issue ID
   * @param includeData - Additional data to include
   * @returns Issue details
   */
  async getIssue(issueId: number, includeData: string[] = []) {
    console.error(`Fetching issue: ${issueId}`);
    
    const params: Record<string, any> = {};
    
    // Add include parameter if specified
    if (includeData.length > 0) {
      params.include = includeData.join(',');
    }
    
    try {
      const response = await this.api.get(`/issues/${issueId}.json`, { params });
      return response.data.issue;
    } catch (error) {
      console.error(`Error fetching issue ${issueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'getIssue',
        error_message: `Failed to fetch Redmine issue: ${(error as Error).message}`,
        context: { issueId, includeData }
      });
      
      throw new Error(`Failed to fetch Redmine issue: ${(error as Error).message}`);
    }
  }

  /**
   * Create a new issue
   * @param projectId - Project ID
   * @param subject - Issue subject
   * @param description - Issue description
   * @param trackerId - Tracker ID
   * @param statusId - Status ID
   * @param priorityId - Priority ID
   * @param assignedToId - Assignee ID
   * @returns Created issue
   */
  async createIssue(
    projectId: number,
    subject: string,
    description?: string,
    trackerId?: number,
    statusId?: number,
    priorityId?: number,
    assignedToId?: number
  ) {
    console.error(`Creating issue: "${subject}" for project ${projectId}`);
    console.error(`Parameters: projectId=${projectId}, subject="${subject}", description=${description ? "provided" : "undefined"}`);
    console.error(`Parameters: trackerId=${trackerId}, statusId=${statusId}, priorityId=${priorityId}, assignedToId=${assignedToId}`);
    
    // Parameter validation
    if (!projectId) {
      const errorMessage = 'Project ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createIssue',
        error_message: errorMessage,
        context: { projectId, subject }
      });
      
      throw new Error(errorMessage);
    }
    
    if (!subject || subject.trim() === '') {
      const errorMessage = 'Subject is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createIssue',
        error_message: errorMessage,
        context: { projectId, subject }
      });
      
      throw new Error(errorMessage);
    }
    
    // Create properly structured data object - ensure correct nesting
    const data: Record<string, any> = {
      issue: {
        project_id: projectId,
        subject: subject.trim()
      }
    };
    
    // Add optional parameters if specified - with type checking
    if (description !== undefined && description !== null) {
      data.issue.description = description;
    }
    
    if (trackerId !== undefined && trackerId !== null) {
      data.issue.tracker_id = Number(trackerId);
    }
    
    if (statusId !== undefined && statusId !== null) {
      data.issue.status_id = Number(statusId);
    }
    
    if (priorityId !== undefined && priorityId !== null) {
      data.issue.priority_id = Number(priorityId);
    }
    
    if (assignedToId !== undefined && assignedToId !== null) {
      data.issue.assigned_to_id = Number(assignedToId);
    }
    
    // Log the exact payload being sent (for debugging)
    console.error(`Request payload: ${JSON.stringify(data, null, 2)}`);
    
    try {
      // Add extra validation for the URL
      const url = '/issues.json';
      console.error(`Making POST request to: ${this.baseUrl}${url}`);
      
      // Check if API key is present
      if (!this.apiKey) {
        const errorMessage = 'API key is not configured';
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'critical',
          component: 'RedmineClient',
          operation: 'createIssue',
          error_message: errorMessage,
          context: { projectId, subject }
        });
        
        throw new Error(errorMessage);
      }
      
      // Make the request with explicit configuration
      const response = await this.api.post(url, data, {
        headers: {
          'X-Redmine-API-Key': this.apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });
      
      console.error(`Response status: ${response.status}`);
      console.error(`Response data: ${JSON.stringify(response.data, null, 2)}`);
      
      if (!response.data || !response.data.issue) {
        const errorMessage = 'Unexpected response format from Redmine API';
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'RedmineClient',
          operation: 'createIssue',
          error_message: errorMessage,
          context: { 
            projectId, 
            subject, 
            response: response.data 
          }
        });
        
        throw new Error(errorMessage);
      }
      
      return response.data.issue;
    } catch (error) {
      console.error('Error creating issue:', error);
      
      // Enhanced error reporting with detailed information
      let errorMessage = `Failed to create Redmine issue: ${(error as Error).message}`;
      let errorDetails = {};
      
      if (axios.isAxiosError(error)) {
        if (error.response) {
          console.error(`Status: ${error.response.status}`);
          console.error(`Response headers: ${JSON.stringify(error.response.headers, null, 2)}`);
          console.error(`Response data: ${JSON.stringify(error.response.data, null, 2)}`);
          
          // Extract specific error messages if available
          const axiosErrorDetails = error.response.data?.errors || [];
          if (axiosErrorDetails.length > 0) {
            console.error(`Specific errors: ${JSON.stringify(axiosErrorDetails, null, 2)}`);
            errorMessage = `Failed to create Redmine issue: ${axiosErrorDetails.join(', ')}`;
            errorDetails = { errors: axiosErrorDetails };
          }
        } else if (error.request) {
          console.error('Error: No response received from server');
          console.error(`Request details: ${JSON.stringify(error.request, null, 2)}`);
          errorDetails = { request: 'No response received from server' };
        } else {
          console.error(`Error setting up request: ${error.message}`);
          errorDetails = { setup: error.message };
        }
        
        // Include request details in error message
        console.error(`Request config: ${JSON.stringify(error.config, null, 2)}`);
      }
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'createIssue',
        error_message: errorMessage,
        stack_trace: (error as Error).stack,
        context: { 
          projectId, 
          subject, 
          trackerId,
          statusId,
          priorityId,
          assignedToId,
          request: data,
          errorDetails
        }
      });
      
      throw new Error(errorMessage);
    }
  }

  /**
   * Update an existing issue
   * @param issueId - Issue ID
   * @param params - Parameters to update
   * @returns True if successful
   */
  async updateIssue(issueId: number, params: Record<string, any>) {
    console.error(`Updating issue: ${issueId}`);
    console.error(`Update parameters: ${JSON.stringify(params, null, 2)}`);
    
    // Special handling for project_id to ensure proper project transfer
    if (params.project_id !== undefined) {
      console.error(`Moving issue to project_id: ${params.project_id}`);
      
      // The full parameters need to be included when changing project
      try {
        // First get the current issue to preserve other fields
        const currentIssue = await this.getIssue(issueId);
        console.error(`Current issue data: ${JSON.stringify(currentIssue, null, 2)}`);
        
        // Create a complete payload with both current and new values
        const completeParams: Record<string, any> = {
          project_id: params.project_id,
          tracker_id: currentIssue.tracker.id,
          status_id: currentIssue.status.id,
          priority_id: currentIssue.priority.id,
          subject: currentIssue.subject,
        };
        
        // Add description if available
        if (currentIssue.description) {
          completeParams.description = currentIssue.description;
        }
        
        // Override with any new values provided in params
        Object.keys(params).forEach(key => {
          if (params[key] !== undefined) {
            completeParams[key] = params[key];
          }
        });
        
        console.error(`Complete update parameters: ${JSON.stringify(completeParams, null, 2)}`);
        
        // Include the notes parameter to log the project change
        if (!completeParams.notes) {
          completeParams.notes = `Moved to project ID: ${params.project_id}`;
        }
        
        // Make the API call with the complete payload
        const response = await this.api.put(`/issues/${issueId}.json`, { 
          issue: completeParams 
        });
        
        console.error(`Update response: ${JSON.stringify(response.data, null, 2)}`);
        
        // Verify the issue was actually moved
        try {
          // Wait a moment to ensure the update is processed
          await new Promise(resolve => setTimeout(resolve, 1000));
          
          // Fetch the updated issue
          const updatedIssue = await this.getIssue(issueId);
          
          // Check if the project ID was actually updated
          if (updatedIssue.project.id !== params.project_id) {
            const errorMessage = `Issue was not properly moved to project ID ${params.project_id}`;
            console.error(`Error: ${errorMessage}`);
            
            // Log error to todo.yaml
            await this.logError({
              timestamp: new Date().toISOString(),
              level: 'warning',
              component: 'RedmineClient',
              operation: 'updateIssue',
              error_message: errorMessage,
              context: { 
                issueId, 
                targetProjectId: params.project_id,
                currentProjectId: updatedIssue.project.id 
              },
              action: 'Issue may need to be manually moved to correct project'
            });
          }
        } catch (verifyError) {
          console.error(`Warning: Unable to verify issue transfer:`, verifyError);
          
          // Log warning to todo.yaml
          await this.logError({
            timestamp: new Date().toISOString(),
            level: 'warning',
            component: 'RedmineClient',
            operation: 'updateIssue',
            error_message: `Unable to verify issue transfer: ${(verifyError as Error).message}`,
            context: { 
              issueId, 
              targetProjectId: params.project_id 
            },
            action: 'Verify issue was moved correctly'
          });
        }
        
        return true;
      } catch (error) {
        console.error(`Error updating issue ${issueId} with project change:`, error);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'RedmineClient',
          operation: 'updateIssue',
          error_message: `Failed to update Redmine issue with project change: ${(error as Error).message}`,
          stack_trace: (error as Error).stack,
          context: { 
            issueId, 
            params
          }
        });
        
        if (axios.isAxiosError(error) && error.response) {
          console.error(`Status: ${error.response.status}`);
          console.error(`Response data: ${JSON.stringify(error.response.data, null, 2)}`);
        }
        throw new Error(`Failed to update Redmine issue with project change: ${(error as Error).message}`);
      }
    } else {
      // Regular update without project change
      try {
        const response = await this.api.put(`/issues/${issueId}.json`, { issue: params });
        console.error(`Update response status: ${response.status}`);
        return true;
      } catch (error) {
        console.error(`Error updating issue ${issueId}:`, error);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'RedmineClient',
          operation: 'updateIssue',
          error_message: `Failed to update Redmine issue: ${(error as Error).message}`,
          context: { 
            issueId, 
            params 
          }
        });
        
        if (axios.isAxiosError(error) && error.response) {
          console.error(`Status: ${error.response.status}`);
          console.error(`Response data: ${JSON.stringify(error.response.data, null, 2)}`);
        }
        throw new Error(`Failed to update Redmine issue: ${(error as Error).message}`);
      }
    }
  }
  
  /**
   * Get current user information
   * @returns Current user details
   */
  async getCurrentUser() {
    console.error('Fetching current user info');
    
    try {
      const response = await this.api.get('/users/current.json');
      return response.data.user;
    } catch (error) {
      console.error('Error fetching current user:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'getCurrentUser',
        error_message: `Failed to fetch current Redmine user: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch current Redmine user: ${(error as Error).message}`);
    }
  }

  /**
   * Test connection to Redmine
   * @returns True if connection successful
   */
  async testConnection() {
    console.error('Testing connection to Redmine');
    
    try {
      // Connect to a specific endpoint instead of root
      await this.api.get('/projects.json');
      console.error('Connection successful');
      return true;
    } catch (error) {
      console.error('Connection failed:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'RedmineClient',
        operation: 'testConnection',
        error_message: `Failed to connect to Redmine: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to connect to Redmine: ${(error as Error).message}`);
    }
  }
}