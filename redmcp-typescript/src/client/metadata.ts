/**
 * Metadata Client Module
 * Provides API methods for interacting with Redmine metadata
 * (statuses, trackers, priorities, etc.)
 */
import axios, { AxiosInstance } from 'axios';
import * as path from 'path';
import { logToTodo } from '../core/logging.js';
import { ErrorLogEntry } from '../core/types.js';

export class MetadataClient {
  private api: AxiosInstance;
  private baseUrl: string;
  private apiKey: string;
  private todoFilePath: string;

  /**
   * Create a new Metadata API client
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
        'Accept': 'application/json'
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

    console.error(`Initialized Metadata client for ${baseUrl}`);
  }

  /**
   * Get list of issue statuses
   * @returns List of issue statuses
   */
  async getIssueStatuses(): Promise<any[]> {
    console.error('Fetching issue statuses');
    
    try {
      const response = await this.api.get('/issue_statuses.json');
      return response.data.issue_statuses;
    } catch (error) {
      console.error('Error fetching issue statuses:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getIssueStatuses',
        error_message: `Failed to fetch issue statuses: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch issue statuses: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of trackers
   * @returns List of trackers
   */
  async getTrackers(): Promise<any[]> {
    console.error('Fetching trackers');
    
    try {
      const response = await this.api.get('/trackers.json');
      return response.data.trackers;
    } catch (error) {
      console.error('Error fetching trackers:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getTrackers',
        error_message: `Failed to fetch trackers: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch trackers: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of issue priorities
   * @returns List of issue priorities
   */
  async getIssuePriorities(): Promise<any[]> {
    console.error('Fetching issue priorities');
    
    try {
      const response = await this.api.get('/enumerations/issue_priorities.json');
      return response.data.issue_priorities;
    } catch (error) {
      console.error('Error fetching issue priorities:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getIssuePriorities',
        error_message: `Failed to fetch issue priorities: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch issue priorities: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of time entry activities
   * @returns List of time entry activities
   */
  async getTimeEntryActivities(): Promise<any[]> {
    console.error('Fetching time entry activities');
    
    try {
      const response = await this.api.get('/enumerations/time_entry_activities.json');
      return response.data.time_entry_activities;
    } catch (error) {
      console.error('Error fetching time entry activities:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getTimeEntryActivities',
        error_message: `Failed to fetch time entry activities: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch time entry activities: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of document categories
   * @returns List of document categories
   */
  async getDocumentCategories(): Promise<any[]> {
    console.error('Fetching document categories');
    
    try {
      const response = await this.api.get('/enumerations/document_categories.json');
      return response.data.document_categories;
    } catch (error) {
      console.error('Error fetching document categories:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getDocumentCategories',
        error_message: `Failed to fetch document categories: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch document categories: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of users
   * @param projectId - Optional project ID to filter users
   * @returns List of users
   */
  async getUsers(projectId?: number): Promise<any[]> {
    console.error(`Fetching users${projectId ? ` for project ${projectId}` : ''}`);
    
    const params: Record<string, any> = {};
    if (projectId) {
      params.project_id = projectId;
    }
    
    try {
      const response = await this.api.get('/users.json', { params });
      return response.data.users;
    } catch (error) {
      console.error('Error fetching users:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getUsers',
        error_message: `Failed to fetch users: ${(error as Error).message}`,
        context: { projectId }
      });
      
      throw new Error(`Failed to fetch users: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of issue categories for a project
   * @param projectId - Project ID or identifier
   * @returns List of issue categories
   */
  async getIssueCategories(projectId: string | number): Promise<any[]> {
    console.error(`Fetching issue categories for project ${projectId}`);
    
    try {
      const response = await this.api.get(`/projects/${projectId}/issue_categories.json`);
      return response.data.issue_categories;
    } catch (error) {
      console.error(`Error fetching issue categories for project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getIssueCategories',
        error_message: `Failed to fetch issue categories: ${(error as Error).message}`,
        context: { projectId }
      });
      
      throw new Error(`Failed to fetch issue categories: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of custom fields
   * @returns List of custom fields
   */
  async getCustomFields(): Promise<any[]> {
    console.error('Fetching custom fields');
    
    try {
      const response = await this.api.get('/custom_fields.json');
      return response.data.custom_fields;
    } catch (error) {
      console.error('Error fetching custom fields:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getCustomFields',
        error_message: `Failed to fetch custom fields: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch custom fields: ${(error as Error).message}`);
    }
  }

  /**
   * Get list of issue relations (relation types)
   * @returns List of issue relation types
   */
  async getIssueRelationTypes(): Promise<any[]> {
    console.error('Fetching issue relation types');
    
    try {
      const response = await this.api.get('/relations.json');
      return response.data.relation_types || [];
    } catch (error) {
      console.error('Error fetching issue relation types:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getIssueRelationTypes',
        error_message: `Failed to fetch issue relation types: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch issue relation types: ${(error as Error).message}`);
    }
  }

  /**
   * Get server info and settings
   * @returns Server info
   */
  async getServerInfo(): Promise<any> {
    console.error('Fetching server info');
    
    try {
      // Note: This endpoint might not be available in all Redmine versions
      const response = await this.api.get('/settings.json');
      return response.data.settings;
    } catch (error) {
      console.error('Error fetching server info:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'MetadataClient',
        operation: 'getServerInfo',
        error_message: `Failed to fetch server info: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch server info: ${(error as Error).message}`);
    }
  }

  /**
   * Log error to the todo.yaml file
   * @param errorInfo - Error information to log
   */
  private async logError(errorInfo: ErrorLogEntry): Promise<void> {
    await logToTodo(this.todoFilePath, errorInfo);
  }
}
