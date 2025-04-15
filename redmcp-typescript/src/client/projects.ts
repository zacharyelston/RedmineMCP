/**
 * Redmine Projects API Client Module
 * Handles all project-related API calls
 */
import { BaseRedmineClient } from './base.js';
import axios from 'axios';

export class ProjectsClient extends BaseRedmineClient {
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
  ): Promise<any> {
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
        component: 'ProjectsClient',
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
        component: 'ProjectsClient',
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
      // Ensure parent_id is converted to a number - explicit Number conversion
      data.project.parent_id = Number(parentId);
      
      // Log the exact parent_id being sent for debugging
      console.error(`Setting parent_id: ${data.project.parent_id} (${typeof data.project.parent_id})`);
      
      // Verify parent project exists before attempting to create subproject
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
          component: 'ProjectsClient',
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
      // Make the request with explicit headers
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
          component: 'ProjectsClient',
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
      
      // Verify project creation - especially important for subprojects
      try {
        // Wait longer (3 seconds) for parent project association to be established in database
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Fetch the project to confirm it exists
        const createdProject = await this.getProject(identifier);
        
        // Enhanced verification for parent_id
        if (parentId && (!createdProject.parent || createdProject.parent.id !== parentId)) {
          const errorMessage = `Project created but not properly associated with parent ID ${parentId}`;
          console.error(`Error: ${errorMessage}`);
          
          // Try to get the parent project details to verify it exists
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
            component: 'ProjectsClient',
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
        }
        
        return createdProject;
      } catch (verifyError) {
        // Project was created but verification failed
        console.error(`Warning: Project created but verification failed:`, verifyError);
        
        // Log warning to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'warning',
          component: 'ProjectsClient',
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
            
            // Check for parent_id related errors
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
        component: 'ProjectsClient',
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
  async getProjects(limit: number = 25, offset: number = 0, sort: string = 'name:asc'): Promise<any[]> {
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
        component: 'ProjectsClient',
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
  async getProject(identifier: string, includeData: string[] = []): Promise<any> {
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
        component: 'ProjectsClient',
        operation: 'getProject',
        error_message: `Failed to fetch Redmine project: ${(error as Error).message}`,
        context: { identifier, includeData }
      });
      
      throw new Error(`Failed to fetch Redmine project: ${(error as Error).message}`);
    }
  }
}
