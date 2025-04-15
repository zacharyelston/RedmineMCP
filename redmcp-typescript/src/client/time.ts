/**
 * Time Tracking Client Module
 * Provides API methods for interacting with Redmine Time Entries
 */
import axios, { AxiosInstance } from 'axios';
import * as path from 'path';
import { logToTodo } from '../core/logging.js';
import { ErrorLogEntry } from '../core/types.js';

export class TimeClient {
  private api: AxiosInstance;
  private baseUrl: string;
  private apiKey: string;
  private todoFilePath: string;

  /**
   * Create a new Time Tracking API client
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

    console.error(`Initialized Time Tracking client for ${baseUrl}`);
  }

  /**
   * Get a list of time entries
   * @param issueId - Optional issue ID to filter time entries
   * @param projectId - Optional project ID to filter time entries
   * @param userId - Optional user ID to filter time entries
   * @param from - Optional start date to filter time entries
   * @param to - Optional end date to filter time entries
   * @param limit - Maximum number of time entries to return
   * @param offset - Pagination offset
   * @returns List of time entries
   */
  async getTimeEntries(
    issueId?: number,
    projectId?: number,
    userId?: number,
    from?: string,
    to?: string,
    limit: number = 25,
    offset: number = 0
  ): Promise<any[]> {
    console.error(`Fetching time entries (issue: ${issueId || 'all'}, project: ${projectId || 'all'}, limit: ${limit}, offset: ${offset})`);
    
    const params: Record<string, any> = {
      limit,
      offset
    };
    
    // Add filters if specified
    if (issueId) params.issue_id = issueId;
    if (projectId) params.project_id = projectId;
    if (userId) params.user_id = userId;
    if (from) params.from = from;
    if (to) params.to = to;
    
    try {
      const response = await this.api.get('/time_entries.json', { params });
      return response.data.time_entries;
    } catch (error) {
      console.error('Error fetching time entries:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'getTimeEntries',
        error_message: `Failed to fetch time entries: ${(error as Error).message}`,
        context: { issueId, projectId, userId, from, to, limit, offset }
      });
      
      throw new Error(`Failed to fetch time entries: ${(error as Error).message}`);
    }
  }

  /**
   * Get a specific time entry
   * @param timeEntryId - Time entry ID
   * @returns Time entry details
   */
  async getTimeEntry(timeEntryId: number): Promise<any> {
    console.error(`Fetching time entry: ${timeEntryId}`);
    
    try {
      const response = await this.api.get(`/time_entries/${timeEntryId}.json`);
      return response.data.time_entry;
    } catch (error) {
      console.error(`Error fetching time entry ${timeEntryId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'getTimeEntry',
        error_message: `Failed to fetch time entry: ${(error as Error).message}`,
        context: { timeEntryId }
      });
      
      throw new Error(`Failed to fetch time entry: ${(error as Error).message}`);
    }
  }

  /**
   * Create a new time entry
   * @param issueId - Issue ID (either issueId or projectId must be specified)
   * @param projectId - Project ID (either issueId or projectId must be specified)
   * @param hours - Hours spent
   * @param activityId - Activity ID
   * @param spentOn - Date when time was spent (YYYY-MM-DD)
   * @param comments - Optional comments
   * @returns Created time entry
   */
  async createTimeEntry(
    issueId: number | null,
    projectId: number | null,
    hours: number,
    activityId: number,
    spentOn: string,
    comments?: string
  ): Promise<any> {
    console.error(`Creating time entry (issue: ${issueId || 'none'}, project: ${projectId || 'none'}, hours: ${hours})`);
    
    // Parameter validation
    if (!issueId && !projectId) {
      const errorMessage = 'Either issue_id or project_id must be specified';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'createTimeEntry',
        error_message: errorMessage,
        context: { issueId, projectId, hours }
      });
      
      throw new Error(errorMessage);
    }
    
    if (hours <= 0) {
      const errorMessage = 'Hours must be greater than 0';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'createTimeEntry',
        error_message: errorMessage,
        context: { issueId, projectId, hours }
      });
      
      throw new Error(errorMessage);
    }
    
    // Create properly structured data object
    const data: Record<string, any> = {
      time_entry: {
        hours: hours,
        activity_id: activityId,
        spent_on: spentOn
      }
    };
    
    // Add issue_id or project_id
    if (issueId) {
      data.time_entry.issue_id = issueId;
    } else {
      data.time_entry.project_id = projectId;
    }
    
    // Add comments if specified
    if (comments) {
      data.time_entry.comments = comments;
    }
    
    try {
      const response = await this.api.post('/time_entries.json', data);
      return response.data.time_entry;
    } catch (error) {
      console.error('Error creating time entry:', error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'createTimeEntry',
        error_message: `Failed to create time entry: ${(error as Error).message}`,
        context: { issueId, projectId, hours, activityId, spentOn, comments }
      });
      
      throw new Error(`Failed to create time entry: ${(error as Error).message}`);
    }
  }

  /**
   * Update an existing time entry
   * @param timeEntryId - Time entry ID
   * @param hours - Hours spent
   * @param activityId - Activity ID
   * @param spentOn - Date when time was spent (YYYY-MM-DD)
   * @param comments - Optional comments
   * @returns True if successful
   */
  async updateTimeEntry(
    timeEntryId: number,
    hours?: number,
    activityId?: number,
    spentOn?: string,
    comments?: string
  ): Promise<boolean> {
    console.error(`Updating time entry: ${timeEntryId}`);
    
    // Create data object with only specified fields
    const data: Record<string, any> = {
      time_entry: {}
    };
    
    if (hours !== undefined) data.time_entry.hours = hours;
    if (activityId !== undefined) data.time_entry.activity_id = activityId;
    if (spentOn !== undefined) data.time_entry.spent_on = spentOn;
    if (comments !== undefined) data.time_entry.comments = comments;
    
    // Ensure there's at least one field to update
    if (Object.keys(data.time_entry).length === 0) {
      const errorMessage = 'No fields specified for update';
      console.error(`Error: ${errorMessage}`);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'updateTimeEntry',
        error_message: errorMessage,
        context: { timeEntryId }
      });
      
      throw new Error(errorMessage);
    }
    
    try {
      await this.api.put(`/time_entries/${timeEntryId}.json`, data);
      return true;
    } catch (error) {
      console.error(`Error updating time entry ${timeEntryId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'updateTimeEntry',
        error_message: `Failed to update time entry: ${(error as Error).message}`,
        context: { timeEntryId, hours, activityId, spentOn, comments }
      });
      
      throw new Error(`Failed to update time entry: ${(error as Error).message}`);
    }
  }

  /**
   * Delete a time entry
   * @param timeEntryId - Time entry ID
   * @returns True if successful
   */
  async deleteTimeEntry(timeEntryId: number): Promise<boolean> {
    console.error(`Deleting time entry: ${timeEntryId}`);
    
    try {
      await this.api.delete(`/time_entries/${timeEntryId}.json`);
      return true;
    } catch (error) {
      console.error(`Error deleting time entry ${timeEntryId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'TimeClient',
        operation: 'deleteTimeEntry',
        error_message: `Failed to delete time entry: ${(error as Error).message}`,
        context: { timeEntryId }
      });
      
      throw new Error(`Failed to delete time entry: ${(error as Error).message}`);
    }
  }

  /**
   * Get time entry activities
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
        component: 'TimeClient',
        operation: 'getTimeEntryActivities',
        error_message: `Failed to fetch time entry activities: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch time entry activities: ${(error as Error).message}`);
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
