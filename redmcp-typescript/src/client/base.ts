/**
 * Base Redmine API Client
 * Provides core functionality for API communication
 */
import axios, { AxiosInstance } from 'axios';
import * as fs from 'fs';
import * as path from 'path';
import { ErrorLogEntry } from '../core/types.js';

export class BaseRedmineClient {
  protected api: AxiosInstance;
  protected baseUrl: string;
  protected apiKey: string;
  protected todoFilePath: string;

  /**
   * Create a new base Redmine API client
   * @param baseUrl - The base URL of the Redmine instance
   * @param apiKey - API key for authentication
   * @param todoFilePath - Path to the todo.yaml file for error logging
   */
  constructor(baseUrl: string, apiKey: string, todoFilePath: string) {
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
  protected async logError(errorInfo: ErrorLogEntry): Promise<void> {
    try {
      // Create error log entry
      const errorEntry = {
        timestamp: errorInfo.timestamp || new Date().toISOString(),
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
   * Test connection to Redmine
   * @returns True if connection successful
   */
  async testConnection(): Promise<boolean> {
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
        component: 'BaseRedmineClient',
        operation: 'testConnection',
        error_message: `Failed to connect to Redmine: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to connect to Redmine: ${(error as Error).message}`);
    }
  }

  /**
   * Get current user information
   * @returns Current user details
   */
  async getCurrentUser(): Promise<any> {
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
        component: 'BaseRedmineClient',
        operation: 'getCurrentUser',
        error_message: `Failed to fetch current Redmine user: ${(error as Error).message}`
      });
      
      throw new Error(`Failed to fetch current Redmine user: ${(error as Error).message}`);
    }
  }
}
