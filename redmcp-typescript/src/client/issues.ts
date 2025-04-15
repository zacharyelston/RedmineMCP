/**
 * Redmine Issues API Client Module
 * Handles all issue-related API calls
 */
import { BaseRedmineClient } from './base.js';
import axios from 'axios';

export class IssuesClient extends BaseRedmineClient {
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
  async getIssues(
    projectId?: string, 
    statusId?: string, 
    trackerId?: number, 
    limit: number = 25, 
    offset: number = 0, 
    sort: string = 'updated_on:desc'
  ): Promise<any[]> {
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
        component: 'IssuesClient',
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
  async getIssue(issueId: number, includeData: string[] = []): Promise<any> {
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
        component: 'IssuesClient',
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
   * @param parentIssueId - Parent issue ID (for creating subtasks)
   * @returns Created issue
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
    console.error(`Creating issue: "${subject}" for project ${projectId}`);
    console.error(`Parameters: projectId=${projectId}, subject="${subject}", description=${description ? "provided" : "undefined"}`);
    console.error(`Parameters: trackerId=${trackerId}, statusId=${statusId}, priorityId=${priorityId}, assignedToId=${assignedToId}`);
    
    if (parentIssueId) {
      console.error(`Creating subtask of issue ${parentIssueId}`);
    }
    
    // Parameter validation
    if (!projectId) {
      const errorMessage = 'Project ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createIssue',
        error_message: errorMessage,
        context: { projectId, subject, parentIssueId }
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
        component: 'IssuesClient',
        operation: 'createIssue',
        error_message: errorMessage,
        context: { projectId, subject, parentIssueId }
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
    
    // Add parent issue ID if specified for creating a subtask
    if (parentIssueId !== undefined && parentIssueId !== null) {
      data.issue.parent_issue_id = Number(parentIssueId);
      
      // Verify parent issue exists before attempting to create subtask
      try {
        // Attempt to get the parent issue to verify it exists
        const parentIssue = await this.getIssue(Number(parentIssueId));
        console.error(`Parent issue verified: ${parentIssue.subject} (ID: ${parentIssue.id})`);
      } catch (parentError) {
        const errorMessage = `Parent issue with ID ${parentIssueId} could not be found or accessed`;
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'IssuesClient',
          operation: 'createIssue',
          error_message: errorMessage,
          context: { projectId, subject, parentIssueId }
        });
        
        throw new Error(errorMessage);
      }
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
          component: 'IssuesClient',
          operation: 'createIssue',
          error_message: errorMessage,
          context: { projectId, subject, parentIssueId }
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
          component: 'IssuesClient',
          operation: 'createIssue',
          error_message: errorMessage,
          context: { 
            projectId, 
            subject, 
            parentIssueId,
            response: response.data 
          }
        });
        
        throw new Error(errorMessage);
      }
      
      // Verify parent-child relationship if creating a subtask
      if (parentIssueId && (!response.data.issue.parent || response.data.issue.parent.id !== parentIssueId)) {
        console.error(`Warning: Issue created but parent-child relationship may not be correctly established`);
        
        // Try to verify by fetching the created issue
        try {
          // Wait a moment to ensure the update is processed
          await new Promise(resolve => setTimeout(resolve, 1000));
          
          // Fetch the created issue
          const createdIssue = await this.getIssue(response.data.issue.id);
          
          // Check if the parent ID was actually set
          if (!createdIssue.parent || createdIssue.parent.id !== parentIssueId) {
            const warningMessage = `Issue created but parent-child relationship was not established with parent ID ${parentIssueId}`;
            console.error(`Warning: ${warningMessage}`);
            
            // Log warning to todo.yaml
            await this.logError({
              timestamp: new Date().toISOString(),
              level: 'warning',
              component: 'IssuesClient',
              operation: 'createIssue',
              error_message: warningMessage,
              context: { 
                projectId, 
                subject, 
                expectedParentId: parentIssueId,
                createdIssueId: createdIssue.id 
              },
              action: 'Issue may need to be manually linked to parent'
            });
          }
        } catch (verifyError) {
          console.error(`Warning: Unable to verify parent-child relationship:`, verifyError);
        }
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
        component: 'IssuesClient',
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
          parentIssueId,
          request: data,
          errorDetails
        }
      });
      
      throw new Error(errorMessage);
    }
  }

  /**
   * Create a subtask under a parent issue
   * @param parentIssueId - ID of parent issue
   * @param subject - Subtask subject
   * @param description - Subtask description
   * @param trackerId - Tracker ID
   * @param statusId - Status ID
   * @param priorityId - Priority ID
   * @returns Created subtask
   */
  async createSubtask(
    parentIssueId: number,
    subject: string,
    description?: string,
    trackerId?: number,
    statusId?: number,
    priorityId?: number
  ): Promise<any> {
    console.error(`Creating subtask: "${subject}" under parent issue ${parentIssueId}`);
    
    try {
      // First get the parent issue to use its project
      const parentIssue = await this.getIssue(parentIssueId);
      
      // Create a subtask using the parent's project ID
      return this.createIssue(
        parentIssue.project.id,
        subject,
        description,
        trackerId,
        statusId,
        priorityId,
        undefined, // No assignee
        parentIssueId // Specify parent issue ID
      );
    } catch (error) {
      console.error(`Error creating subtask under parent ${parentIssueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createSubtask',
        error_message: `Failed to create subtask: ${(error as Error).message}`,
        context: { 
          parentIssueId, 
          subject, 
          trackerId,
          statusId,
          priorityId
        }
      });
      
      throw new Error(`Failed to create subtask: ${(error as Error).message}`);
    }
  }

  /**
   * Update an existing issue
   * @param issueId - Issue ID
   * @param params - Parameters to update
   * @returns True if successful
   */
  async updateIssue(issueId: number, params: Record<string, any>): Promise<boolean> {
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
              component: 'IssuesClient',
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
            component: 'IssuesClient',
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
          component: 'IssuesClient',
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
          component: 'IssuesClient',
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
   * Add a parent to an existing issue (make it a subtask)
   * @param issueId - ID of the issue to update
   * @param parentIssueId - ID of the parent issue
   * @returns True if successful
   */
  async setParentIssue(issueId: number, parentIssueId: number): Promise<boolean> {
    console.error(`Setting parent issue: ${parentIssueId} for issue ${issueId}`);
    
    // Verify parent issue exists
    try {
      const parentIssue = await this.getIssue(parentIssueId);
      console.error(`Parent issue verified: ${parentIssue.subject} (ID: ${parentIssue.id})`);
    } catch (parentError) {
      const errorMessage = `Parent issue with ID ${parentIssueId} could not be found or accessed`;
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'setParentIssue',
        error_message: errorMessage,
        context: { issueId, parentIssueId }
      });
      
      throw new Error(errorMessage);
    }
    
    // Update the issue with the parent_issue_id parameter
    return this.updateIssue(issueId, { parent_issue_id: parentIssueId });
  }

  /**
   * Remove a parent from an issue (make it a top-level issue)
   * @param issueId - ID of the issue to update
   * @returns True if successful
   */
  async removeParentIssue(issueId: number): Promise<boolean> {
    console.error(`Removing parent from issue ${issueId}`);
    
    // Update the issue with a null parent_issue_id
    return this.updateIssue(issueId, { parent_issue_id: '' });
  }

  /**
   * Get all child issues (subtasks) of a parent issue
   * @param parentIssueId - ID of the parent issue
   * @returns List of child issues
   */
  async getChildIssues(parentIssueId: number): Promise<any[]> {
    console.error(`Getting child issues for parent ${parentIssueId}`);
    
    try {
      // Get the parent issue with children included
      const parentIssue = await this.getIssue(parentIssueId, ['children']);
      
      if (parentIssue.children && Array.isArray(parentIssue.children)) {
        return parentIssue.children;
      }
      
      return [];
    } catch (error) {
      console.error(`Error getting child issues for parent ${parentIssueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'getChildIssues',
        error_message: `Failed to get child issues: ${(error as Error).message}`,
        context: { parentIssueId }
      });
      
      throw new Error(`Failed to get child issues: ${(error as Error).message}`);
    }
  }

  /**
   * Get all relations for a specific issue
   * @param issueId - ID of the issue
   * @returns Array of issue relations
   */
  async getIssueRelations(issueId: number): Promise<any[]> {
    console.error(`Fetching relations for issue: ${issueId}`);
    
    try {
      // Get the issue with relations included
      const issue = await this.getIssue(issueId, ['relations']);
      
      if (issue.relations && Array.isArray(issue.relations)) {
        return issue.relations;
      }
      
      return [];
    } catch (error) {
      console.error(`Error fetching relations for issue ${issueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'getIssueRelations',
        error_message: `Failed to fetch issue relations: ${(error as Error).message}`,
        context: { issueId }
      });
      
      throw new Error(`Failed to fetch issue relations: ${(error as Error).message}`);
    }
  }

  /**
   * Create a relation between two issues
   * @param issueId - ID of the source issue
   * @param targetIssueId - ID of the target issue
   * @param relationType - Type of relation (e.g., 'relates', 'duplicates', 'blocks', 'precedes')
   * @param delay - Delay in days for precedes/follows relations (optional)
   * @returns Created relation
   */
  async createIssueRelation(
    issueId: number,
    targetIssueId: number,
    relationType: string,
    delay?: number
  ): Promise<any> {
    console.error(`Creating relation: ${relationType} between issues ${issueId} and ${targetIssueId}`);
    
    // Parameter validation
    if (!issueId) {
      const errorMessage = 'Source issue ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createIssueRelation',
        error_message: errorMessage,
        context: { issueId, targetIssueId, relationType }
      });
      
      throw new Error(errorMessage);
    }
    
    if (!targetIssueId) {
      const errorMessage = 'Target issue ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createIssueRelation',
        error_message: errorMessage,
        context: { issueId, targetIssueId, relationType }
      });
      
      throw new Error(errorMessage);
    }
    
    if (!relationType || relationType.trim() === '') {
      const errorMessage = 'Relation type is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createIssueRelation',
        error_message: errorMessage,
        context: { issueId, targetIssueId, relationType }
      });
      
      throw new Error(errorMessage);
    }
    
    // Verify both issues exist
    try {
      // Verify source issue
      await this.getIssue(issueId);
      
      // Verify target issue
      await this.getIssue(targetIssueId);
    } catch (verifyError) {
      const errorMessage = `One or both issues could not be found: ${(verifyError as Error).message}`;
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'createIssueRelation',
        error_message: errorMessage,
        context: { issueId, targetIssueId, relationType }
      });
      
      throw new Error(errorMessage);
    }
    
    // Create the relation data
    const data: Record<string, any> = {
      relation: {
        issue_to_id: targetIssueId,
        relation_type: relationType
      }
    };
    
    // Add delay if specified for precedes/follows relations
    if (delay !== undefined && delay > 0 && (relationType === 'precedes' || relationType === 'follows')) {
      data.relation.delay = delay;
    }
    
    // Log the request payload
    console.error(`Request payload: ${JSON.stringify(data, null, 2)}`);
    
    try {
      // Make the API request
      const response = await this.api.post(`/issues/${issueId}/relations.json`, data);
      
      console.error(`Response status: ${response.status}`);
      console.error(`Response data: ${JSON.stringify(response.data, null, 2)}`);
      
      if (!response.data || !response.data.relation) {
        const errorMessage = 'Unexpected response format from Redmine API';
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'IssuesClient',
          operation: 'createIssueRelation',
          error_message: errorMessage,
          context: { 
            issueId, 
            targetIssueId, 
            relationType,
            response: response.data 
          }
        });
        
        throw new Error(errorMessage);
      }
      
      return response.data.relation;
    } catch (error) {
      console.error(`Error creating issue relation:`, error);
      
      // Enhanced error reporting with detailed information
      let errorMessage = `Failed to create issue relation: ${(error as Error).message}`;
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
            errorMessage = `Failed to create issue relation: ${axiosErrorDetails.join(', ')}`;
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
        component: 'IssuesClient',
        operation: 'createIssueRelation',
        error_message: errorMessage,
        stack_trace: (error as Error).stack,
        context: { 
          issueId, 
          targetIssueId, 
          relationType,
          delay,
          request: data,
          errorDetails
        }
      });
      
      throw new Error(errorMessage);
    }
  }

  /**
   * Delete an issue relation
   * @param relationId - ID of the relation to delete
   * @returns True if successful
   */
  async deleteIssueRelation(relationId: number): Promise<boolean> {
    console.error(`Deleting issue relation: ${relationId}`);
    
    // Parameter validation
    if (!relationId) {
      const errorMessage = 'Relation ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'deleteIssueRelation',
        error_message: errorMessage,
        context: { relationId }
      });
      
      throw new Error(errorMessage);
    }
    
    try {
      // Make the API request
      const response = await this.api.delete(`/relations/${relationId}.json`);
      
      console.error(`Response status: ${response.status}`);
      return true;
    } catch (error) {
      console.error(`Error deleting issue relation ${relationId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'deleteIssueRelation',
        error_message: `Failed to delete issue relation: ${(error as Error).message}`,
        context: { relationId }
      });
      
      throw new Error(`Failed to delete issue relation: ${(error as Error).message}`);
    }
  }

  /**
   * Add a comment to an issue
   * @param issueId - Issue ID
   * @param comment - Comment text
   * @returns True if successful
   */
  async addIssueComment(issueId: number, comment: string): Promise<boolean> {
    console.error(`Adding comment to issue ${issueId}`);
    
    // Parameter validation
    if (!issueId) {
      const errorMessage = 'Issue ID is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'addIssueComment',
        error_message: errorMessage,
        context: { issueId, comment }
      });
      
      throw new Error(errorMessage);
    }
    
    if (!comment || comment.trim() === '') {
      const errorMessage = 'Comment text is required';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'addIssueComment',
        error_message: errorMessage,
        context: { issueId, comment }
      });
      
      throw new Error(errorMessage);
    }
    
    // Update the issue with just the notes field
    try {
      return await this.updateIssue(issueId, { notes: comment });
    } catch (error) {
      console.error(`Error adding comment to issue ${issueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'IssuesClient',
        operation: 'addIssueComment',
        error_message: `Failed to add comment to issue: ${(error as Error).message}`,
        context: { issueId, comment }
      });
      
      throw new Error(`Failed to add comment to issue: ${(error as Error).message}`);
    }
  }
}
