/**
 * Attachments Client Module
 * Provides API methods for interacting with Redmine Attachments
 */
import axios, { AxiosInstance, AxiosHeaders } from 'axios';
import * as path from 'path';
import * as fs from 'fs';
// Fix: Import FormData correctly as default import
import FormData from 'form-data';
import { logToTodo } from '../core/logging.js';
import { ErrorLogEntry } from '../core/types.js';

export class AttachmentsClient {
  private api: AxiosInstance;
  private baseUrl: string;
  private apiKey: string;
  private todoFilePath: string;

  /**
   * Create a new Attachments API client
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
      // Add format=json parameter to all requests unless multipart form
      // Fix: Check for includes safely
      const contentType = config.headers?.['Content-Type'];
      if (contentType && typeof contentType === 'string' && !contentType.includes('multipart/form-data')) {
        config.params.format = 'json';
      }
      
      console.error(`Making ${config.method?.toUpperCase()} request to ${config.url}`);
      return config;
    });

    console.error(`Initialized Attachments client for ${baseUrl}`);
  }

  /**
   * Upload a file and get a token for attaching it to an issue/wiki/etc.
   * @param filePath - Path to the file to upload
   * @param filename - Optional custom filename (uses original filename if not specified)
   * @param contentType - Optional content type (auto-detected if not specified)
   * @returns Upload token and attachment info
   */
  async uploadFile(filePath: string, filename?: string, contentType?: string): Promise<any> {
    console.error(`Uploading file: ${filePath}`);
    
    try {
      // Check if file exists
      if (!fs.existsSync(filePath)) {
        const errorMessage = `File does not exist: ${filePath}`;
        console.error(`Error: ${errorMessage}`);
        
        // Log error to todo.yaml
        await this.logError({
          timestamp: new Date().toISOString(),
          level: 'error',
          component: 'AttachmentsClient',
          operation: 'uploadFile',
          error_message: errorMessage,
          context: { filePath, filename }
        });
        
        throw new Error(errorMessage);
      }
      
      // Create form data - fixed: FormData is now imported correctly
      const form = new FormData();
      const fileStream = fs.createReadStream(filePath);
      
      // Use provided filename or extract from path
      const actualFilename = filename || path.basename(filePath);
      
      // Add file to form
      form.append('attachment[file]', fileStream, {
        filename: actualFilename,
        contentType: contentType
      });
      
      // Make request with form data
      const response = await this.api.post('/uploads.json', form, {
        headers: {
          ...form.getHeaders(),
          'X-Redmine-API-Key': this.apiKey
        }
      });
      
      console.error(`File uploaded successfully, token: ${response.data.upload.token}`);
      return response.data.upload;
    } catch (error) {
      console.error(`Error uploading file ${filePath}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'AttachmentsClient',
        operation: 'uploadFile',
        error_message: `Failed to upload file: ${(error as Error).message}`,
        context: { filePath, filename, contentType }
      });
      
      throw new Error(`Failed to upload file: ${(error as Error).message}`);
    }
  }

  /**
   * Get a specific attachment
   * @param attachmentId - Attachment ID
   * @returns Attachment details
   */
  async getAttachment(attachmentId: number): Promise<any> {
    console.error(`Fetching attachment: ${attachmentId}`);
    
    try {
      const response = await this.api.get(`/attachments/${attachmentId}.json`);
      return response.data.attachment;
    } catch (error) {
      console.error(`Error fetching attachment ${attachmentId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'AttachmentsClient',
        operation: 'getAttachment',
        error_message: `Failed to fetch attachment: ${(error as Error).message}`,
        context: { attachmentId }
      });
      
      throw new Error(`Failed to fetch attachment: ${(error as Error).message}`);
    }
  }

  /**
   * Download an attachment content
   * @param attachmentId - Attachment ID
   * @param destinationPath - Path where to save the attachment
   * @returns True if successful
   */
  async downloadAttachment(attachmentId: number, destinationPath: string): Promise<boolean> {
    console.error(`Downloading attachment ${attachmentId} to ${destinationPath}`);
    
    try {
      // Get attachment metadata first
      const attachment = await this.getAttachment(attachmentId);
      console.error(`Attachment found: ${attachment.filename}, content URL: ${attachment.content_url}`);
      
      // Download content (using axios directly with responseType stream)
      const response = await this.api.get(attachment.content_url, {
        responseType: 'stream',
        headers: {
          'X-Redmine-API-Key': this.apiKey
        }
      });
      
      // Create write stream and pipe response data
      const writer = fs.createWriteStream(destinationPath);
      response.data.pipe(writer);
      
      return new Promise<boolean>((resolve, reject) => {
        writer.on('finish', () => {
          console.error(`Attachment downloaded successfully to ${destinationPath}`);
          resolve(true);
        });
        writer.on('error', (err) => {
          console.error(`Error writing attachment to ${destinationPath}:`, err);
          reject(err);
        });
      });
    } catch (error) {
      console.error(`Error downloading attachment ${attachmentId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'AttachmentsClient',
        operation: 'downloadAttachment',
        error_message: `Failed to download attachment: ${(error as Error).message}`,
        context: { attachmentId, destinationPath }
      });
      
      throw new Error(`Failed to download attachment: ${(error as Error).message}`);
    }
  }

  /**
   * Delete an attachment
   * @param attachmentId - Attachment ID
   * @returns True if successful
   */
  async deleteAttachment(attachmentId: number): Promise<boolean> {
    console.error(`Deleting attachment: ${attachmentId}`);
    
    try {
      await this.api.delete(`/attachments/${attachmentId}.json`);
      return true;
    } catch (error) {
      console.error(`Error deleting attachment ${attachmentId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'AttachmentsClient',
        operation: 'deleteAttachment',
        error_message: `Failed to delete attachment: ${(error as Error).message}`,
        context: { attachmentId }
      });
      
      throw new Error(`Failed to delete attachment: ${(error as Error).message}`);
    }
  }

  /**
   * Get all attachments for an issue
   * @param issueId - Issue ID
   * @returns List of attachments
   */
  async getIssueAttachments(issueId: number): Promise<any[]> {
    console.error(`Fetching attachments for issue: ${issueId}`);
    
    try {
      // Get issue with attachments included
      const response = await this.api.get(`/issues/${issueId}.json`, {
        params: {
          include: 'attachments'
        }
      });
      
      return response.data.issue.attachments || [];
    } catch (error) {
      console.error(`Error fetching attachments for issue ${issueId}:`, error);
      
      // Log error to todo.yaml
      await this.logError({
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'AttachmentsClient',
        operation: 'getIssueAttachments',
        error_message: `Failed to fetch issue attachments: ${(error as Error).message}`,
        context: { issueId }
      });
      
      throw new Error(`Failed to fetch issue attachments: ${(error as Error).message}`);
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
