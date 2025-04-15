/**
 * Redmine Client Exports
 * 
 * This file exports the RedmineClient class that composes all client modules
 * into a single client that implements the DataProvider interface.
 */

import { BaseRedmineClient } from './base.js';
import { IssuesClient } from './issues.js';
import { ProjectsClient } from './projects.js';
import { WikiClient } from './wiki.js';
import { TimeClient } from './time.js';
import { AttachmentsClient } from './attachments.js';
import { MetadataClient } from './metadata.js';

export class RedmineClient implements DataProvider {
  private baseClient: BaseRedmineClient;
  private issuesClient: IssuesClient;
  private projectsClient: ProjectsClient;
  private wikiClient: WikiClient;
  private timeClient: TimeClient;
  private attachmentsClient: AttachmentsClient;
  private metadataClient: MetadataClient;

  /**
   * Create a new Redmine API client
   * @param baseUrl - The base URL of the Redmine instance
   * @param apiKey - API key for authentication
   * @param todoFilePath - Path to the todo.yaml file for error logging
   */
  constructor(baseUrl: string, apiKey: string, todoFilePath: string = '../../todo.yaml') {
    this.baseClient = new BaseRedmineClient(baseUrl, apiKey, todoFilePath);
    this.issuesClient = new IssuesClient(baseUrl, apiKey, todoFilePath);
    this.projectsClient = new ProjectsClient(baseUrl, apiKey, todoFilePath);
    this.wikiClient = new WikiClient(baseUrl, apiKey, todoFilePath);
    this.timeClient = new TimeClient(baseUrl, apiKey, todoFilePath);
    this.attachmentsClient = new AttachmentsClient(baseUrl, apiKey, todoFilePath);
    this.metadataClient = new MetadataClient(baseUrl, apiKey, todoFilePath);
  }

  /**
   * Test connection to Redmine
   * @returns True if connection successful
   */
  async testConnection(): Promise<boolean> {
    return this.baseClient.testConnection();
  }

  /**
   * Get current user information
   * @returns Current user details
   */
  async getCurrentUser(): Promise<any> {
    return this.baseClient.getCurrentUser();
  }

  // Project methods

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
    return this.projectsClient.createProject(name, identifier, description, isPublic, parentId);
  }

  /**
   * Get a list of projects
   * @param limit - Maximum number of projects to return
   * @param offset - Pagination offset
   * @param sort - Sort field and direction (field:direction)
   * @returns List of projects
   */
  async getProjects(limit: number = 25, offset: number = 0, sort: string = 'name:asc'): Promise<any[]> {
    return this.projectsClient.getProjects(limit, offset, sort);
  }

  /**
   * Get a specific project by identifier
   * @param identifier - Project identifier
   * @param includeData - Additional data to include
   * @returns Project details
   */
  async getProject(identifier: string, includeData: string[] = []): Promise<any> {
    return this.projectsClient.getProject(identifier, includeData);
  }

  // Issue methods

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
    return this.issuesClient.getIssues(projectId, statusId, trackerId, limit, offset, sort);
  }

  /**
   * Get a specific issue by ID
   * @param issueId - Issue ID
   * @param includeData - Additional data to include
   * @returns Issue details
   */
  async getIssue(issueId: number, includeData: string[] = []): Promise<any> {
    return this.issuesClient.getIssue(issueId, includeData);
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
    return this.issuesClient.createIssue(
      projectId,
      subject,
      description,
      trackerId,
      statusId,
      priorityId,
      assignedToId,
      parentIssueId
    );
  }

  /**
   * Update an existing issue
   * @param issueId - Issue ID
   * @param params - Parameters to update
   * @returns True if successful
   */
  async updateIssue(issueId: number, params: Record<string, any>): Promise<boolean> {
    return this.issuesClient.updateIssue(issueId, params);
  }

  // Additional Issue methods (these are not in the core DataProvider interface yet)

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
    return this.issuesClient.createSubtask(parentIssueId, subject, description, trackerId, statusId, priorityId);
  }

  /**
   * Add a parent to an existing issue (make it a subtask)
   * @param issueId - ID of the issue to update
   * @param parentIssueId - ID of the parent issue
   * @returns True if successful
   */
  async setParentIssue(issueId: number, parentIssueId: number): Promise<boolean> {
    return this.issuesClient.setParentIssue(issueId, parentIssueId);
  }

  /**
   * Remove a parent from an issue (make it a top-level issue)
   * @param issueId - ID of the issue to update
   * @returns True if successful
   */
  async removeParentIssue(issueId: number): Promise<boolean> {
    return this.issuesClient.removeParentIssue(issueId);
  }

  /**
   * Get all child issues (subtasks) of a parent issue
   * @param parentIssueId - ID of the parent issue
   * @returns List of child issues
   */
  async getChildIssues(parentIssueId: number): Promise<any[]> {
    return this.issuesClient.getChildIssues(parentIssueId);
  }

  /**
   * Get all relations for a specific issue
   * @param issueId - ID of the issue
   * @returns Array of issue relations
   */
  async getIssueRelations(issueId: number): Promise<any[]> {
    return this.issuesClient.getIssueRelations(issueId);
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
    return this.issuesClient.createIssueRelation(issueId, targetIssueId, relationType, delay);
  }

  /**
   * Delete an issue relation
   * @param relationId - ID of the relation to delete
   * @returns True if successful
   */
  async deleteIssueRelation(relationId: number): Promise<boolean> {
    return this.issuesClient.deleteIssueRelation(relationId);
  }

  /**
   * Add a comment to an issue
   * @param issueId - Issue ID
   * @param comment - Comment text
   * @returns True if successful
   */
  async addIssueComment(issueId: number, comment: string): Promise<boolean> {
    return this.issuesClient.addIssueComment(issueId, comment);
  }

  // Wiki methods

  /**
   * Get a list of wiki pages for a project
   * @param projectId - Project identifier
   * @returns List of wiki pages
   */
  async getWikiPages(projectId: string): Promise<any[]> {
    return this.wikiClient.getWikiPages(projectId);
  }

  /**
   * Get a specific wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @param version - Optional specific version to retrieve
   * @returns Wiki page content
   */
  async getWikiPage(projectId: string, pageTitle: string, version?: number): Promise<any> {
    return this.wikiClient.getWikiPage(projectId, pageTitle, version);
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
    return this.wikiClient.createOrUpdateWikiPage(projectId, pageTitle, content, comments);
  }

  /**
   * Delete a wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @returns True if successful
   */
  async deleteWikiPage(projectId: string, pageTitle: string): Promise<boolean> {
    return this.wikiClient.deleteWikiPage(projectId, pageTitle);
  }

  /**
   * Get the history (versions) of a wiki page
   * @param projectId - Project identifier
   * @param pageTitle - Wiki page title
   * @returns List of wiki page versions
   */
  async getWikiPageHistory(projectId: string, pageTitle: string): Promise<any[]> {
    return this.wikiClient.getWikiPageHistory(projectId, pageTitle);
  }

  // Time tracking methods

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
    return this.timeClient.getTimeEntries(issueId, projectId, userId, from, to, limit, offset);
  }

  /**
   * Get a specific time entry
   * @param timeEntryId - Time entry ID
   * @returns Time entry details
   */
  async getTimeEntry(timeEntryId: number): Promise<any> {
    return this.timeClient.getTimeEntry(timeEntryId);
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
    return this.timeClient.createTimeEntry(issueId, projectId, hours, activityId, spentOn, comments);
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
    return this.timeClient.updateTimeEntry(timeEntryId, hours, activityId, spentOn, comments);
  }

  /**
   * Delete a time entry
   * @param timeEntryId - Time entry ID
   * @returns True if successful
   */
  async deleteTimeEntry(timeEntryId: number): Promise<boolean> {
    return this.timeClient.deleteTimeEntry(timeEntryId);
  }

  // Attachment methods

  /**
   * Upload a file and get a token for attaching it to an issue/wiki/etc.
   * @param filePath - Path to the file to upload
   * @param filename - Optional custom filename (uses original filename if not specified)
   * @param contentType - Optional content type (auto-detected if not specified)
   * @returns Upload token and attachment info
   */
  async uploadFile(filePath: string, filename?: string, contentType?: string): Promise<any> {
    return this.attachmentsClient.uploadFile(filePath, filename, contentType);
  }

  /**
   * Get a specific attachment
   * @param attachmentId - Attachment ID
   * @returns Attachment details
   */
  async getAttachment(attachmentId: number): Promise<any> {
    return this.attachmentsClient.getAttachment(attachmentId);
  }

  /**
   * Download an attachment content
   * @param attachmentId - Attachment ID
   * @param destinationPath - Path where to save the attachment
   * @returns True if successful
   */
  async downloadAttachment(attachmentId: number, destinationPath: string): Promise<boolean> {
    return this.attachmentsClient.downloadAttachment(attachmentId, destinationPath);
  }

  /**
   * Delete an attachment
   * @param attachmentId - Attachment ID
   * @returns True if successful
   */
  async deleteAttachment(attachmentId: number): Promise<boolean> {
    return this.attachmentsClient.deleteAttachment(attachmentId);
  }

  /**
   * Get all attachments for an issue
   * @param issueId - Issue ID
   * @returns List of attachments
   */
  async getIssueAttachments(issueId: number): Promise<any[]> {
    return this.attachmentsClient.getIssueAttachments(issueId);
  }

  // Metadata methods

  /**
   * Get list of issue statuses
   * @returns List of issue statuses
   */
  async getIssueStatuses(): Promise<any[]> {
    return this.metadataClient.getIssueStatuses();
  }

  /**
   * Get list of trackers
   * @returns List of trackers
   */
  async getTrackers(): Promise<any[]> {
    return this.metadataClient.getTrackers();
  }

  /**
   * Get list of issue priorities
   * @returns List of issue priorities
   */
  async getIssuePriorities(): Promise<any[]> {
    return this.metadataClient.getIssuePriorities();
  }

  /**
   * Get list of time entry activities
   * @returns List of time entry activities
   */
  async getTimeEntryActivities(): Promise<any[]> {
    return this.metadataClient.getTimeEntryActivities();
  }

  /**
   * Get list of users
   * @param projectId - Optional project ID to filter users
   * @returns List of users
   */
  async getUsers(projectId?: number): Promise<any[]> {
    return this.metadataClient.getUsers(projectId);
  }

  /**
   * Get list of issue categories for a project
   * @param projectId - Project ID or identifier
   * @returns List of issue categories
   */
  async getIssueCategories(projectId: string | number): Promise<any[]> {
    return this.metadataClient.getIssueCategories(projectId);
  }

  /**
   * Get list of custom fields
   * @returns List of custom fields
   */
  async getCustomFields(): Promise<any[]> {
    return this.metadataClient.getCustomFields();
  }
}

// Interface for the Redmine data provider
interface DataProvider {
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
  
  // Wiki methods
  getWikiPages?(projectId: string): Promise<any[]>;
  getWikiPage?(projectId: string, pageTitle: string, version?: number): Promise<any>;
  createOrUpdateWikiPage?(projectId: string, pageTitle: string, content: string, comments?: string): Promise<any>;
  deleteWikiPage?(projectId: string, pageTitle: string): Promise<boolean>;
  getWikiPageHistory?(projectId: string, pageTitle: string): Promise<any[]>;
  
  // Time tracking methods
  getTimeEntries?(issueId?: number, projectId?: number, userId?: number, from?: string, to?: string, limit?: number, offset?: number): Promise<any[]>;
  getTimeEntry?(timeEntryId: number): Promise<any>;
  createTimeEntry?(issueId: number | null, projectId: number | null, hours: number, activityId: number, spentOn: string, comments?: string): Promise<any>;
  updateTimeEntry?(timeEntryId: number, hours?: number, activityId?: number, spentOn?: string, comments?: string): Promise<boolean>;
  deleteTimeEntry?(timeEntryId: number): Promise<boolean>;
  
  // Attachment methods
  uploadFile?(filePath: string, filename?: string, contentType?: string): Promise<any>;
  getAttachment?(attachmentId: number): Promise<any>;
  downloadAttachment?(attachmentId: number, destinationPath: string): Promise<boolean>;
  deleteAttachment?(attachmentId: number): Promise<boolean>;
  getIssueAttachments?(issueId: number): Promise<any[]>;
  
  // Metadata methods
  getIssueStatuses?(): Promise<any[]>;
  getTrackers?(): Promise<any[]>;
  getIssuePriorities?(): Promise<any[]>;
  getTimeEntryActivities?(): Promise<any[]>;
  getUsers?(projectId?: number): Promise<any[]>;
  getIssueCategories?(projectId: string | number): Promise<any[]>;
  getCustomFields?(): Promise<any[]>;
  
  // User methods
  getCurrentUser(): Promise<any>;
  
  // Connection test
  testConnection(): Promise<boolean>;
}

export { DataProvider };
