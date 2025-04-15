/**
 * Wiki Client Module
 * Provides API methods for interacting with Redmine Wiki
 */
import axios, { AxiosInstance } from 'axios';
import * as path from 'path';
import { logToTodo } from '../core/logging.js';
import { ErrorLogEntry } from '../core/types.js';

export class WikiClient {
  private api: AxiosInstance;
  private baseUrl: string;
  private apiKey: string;
  private todoFilePath: string;

  /**
   * Create a new Wiki API client
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

    console.error(`Initialized Wiki client for ${baseUrl}`);
  }

  /**
   * Get a list of wiki pages for a project
   * @param projectId - Project identifier
   * @returns List of wiki pages
   */
  async getWikiPages(projectId: string): Promise<any[]> {
    console.error(`Fetching wiki pages for project: ${projectId}`);
    
    try {
      const response = await this.api.get(`/projects/${projectId}/wiki/index.json`);
      return response.data.wiki_pages;
    } catch (error) {
      console.error(`Error fetching wiki pages for project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'WikiClient',
        operation: 'getWikiPages',
        error_message: `Failed to fetch wiki pages: ${(error as Error).message}`,
        context: { projectId }
      });
      
      throw new Error(`Failed to fetch wiki pages: ${(error as Error).message}`);
    }
  }

  /**
   * Get a specific wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @param version - Optional specific version to retrieve
   * @returns Wiki page content
   */
  async getWikiPage(projectId: string, pageTitle: string, version?: number): Promise<any> {
    console.error(`Fetching wiki page "${pageTitle}" for project: ${projectId}`);
    
    try {
      const url = `/projects/${projectId}/wiki/${encodeURIComponent(pageTitle)}.json`;
      const params: Record<string, any> = {};
      
      // Add version parameter if specified
      if (version !== undefined) {
        params.version = version;
      }
      
      const response = await this.api.get(url, { params });
      return response.data.wiki_page;
    } catch (error) {
      console.error(`Error fetching wiki page "${pageTitle}" for project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'WikiClient',
        operation: 'getWikiPage',
        error_message: `Failed to fetch wiki page: ${(error as Error).message}`,
        context: { projectId, pageTitle, version }
      });
      
      throw new Error(`Failed to fetch wiki page: ${(error as Error).message}`);
    }
  }

  /**
   * Create or update a wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @param content - Wiki page content
   * @param comments - Optional comments about the update
   * @returns Created or updated wiki page
   */
  async createOrUpdateWikiPage(
    projectId: string,
    pageTitle: string,
    content: string,
    comments?: string
  ): Promise<any> {
    console.error(`Creating/updating wiki page "${pageTitle}" for project: ${projectId}`);
    
    try {
      // Check if page exists first
      let pageExists = false;
      try {
        await this.getWikiPage(projectId, pageTitle);
        pageExists = true;
      } catch (error) {
        // Page doesn't exist, we'll create a new one
        console.error(`Wiki page "${pageTitle}" doesn't exist yet, will create it`);
      }
      
      const url = `/projects/${projectId}/wiki/${encodeURIComponent(pageTitle)}.json`;
      const method = pageExists ? 'put' : 'post';
      
      // Define wiki_page data with the proper interface
      interface WikiPageData {
        text: string;
        comments?: string;
      }
      
      const wiki_page: WikiPageData = {
        text: content
      };
      
      // Add comments if specified
      if (comments) {
        wiki_page.comments = comments;
      }
      
      const data = {
        wiki_page
      };
      
      const response = await this.api.request({
        method,
        url,
        data
      });
      
      if (method === 'post') {
        // For new pages, get the page to return
        return this.getWikiPage(projectId, pageTitle);
      } else {
        // For updates, the response doesn't include the page content
        return response.data.wiki_page || { title: pageTitle };
      }
    } catch (error) {
      console.error(`Error creating/updating wiki page "${pageTitle}" for project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'WikiClient',
        operation: 'createOrUpdateWikiPage',
        error_message: `Failed to create/update wiki page: ${(error as Error).message}`,
        context: { projectId, pageTitle, comments }
      });
      
      throw new Error(`Failed to create/update wiki page: ${(error as Error).message}`);
    }
  }

  /**
   * Delete a wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @returns True if successful
   */
  async deleteWikiPage(projectId: string, pageTitle: string): Promise<boolean> {
    console.error(`Deleting wiki page "${pageTitle}" for project: ${projectId}`);
    
    try {
      const url = `/projects/${projectId}/wiki/${encodeURIComponent(pageTitle)}.json`;
      await this.api.delete(url);
      return true;
    } catch (error) {
      console.error(`Error deleting wiki page "${pageTitle}" for project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'WikiClient',
        operation: 'deleteWikiPage',
        error_message: `Failed to delete wiki page: ${(error as Error).message}`,
        context: { projectId, pageTitle }
      });
      
      throw new Error(`Failed to delete wiki page: ${(error as Error).message}`);
    }
  }

  /**
   * Get the history (versions) of a wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @returns List of wiki page versions
   */
  async getWikiPageHistory(projectId: string, pageTitle: string): Promise<any[]> {
    console.error(`Fetching history for wiki page "${pageTitle}" in project: ${projectId}`);
    
    try {
      const url = `/projects/${projectId}/wiki/${encodeURIComponent(pageTitle)}/history.json`;
      const response = await this.api.get(url);
      return response.data.wiki_page_versions || [];
    } catch (error) {
      console.error(`Error fetching history for wiki page "${pageTitle}" in project ${projectId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'WikiClient',
        operation: 'getWikiPageHistory',
        error_message: `Failed to fetch wiki page history: ${(error as Error).message}`,
        context: { projectId, pageTitle }
      });
      
      throw new Error(`Failed to fetch wiki page history: ${(error as Error).message}`);
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
