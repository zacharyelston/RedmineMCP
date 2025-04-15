/**
 * Attachments Tools Module
 * Provides MCP tools for interacting with Redmine attachments
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { DataProvider } from '../client/index.js';

/**
 * Register attachment-related tools with the MCP server
 * @param server - MCP server instance
 * @param dataProvider - Data provider for Redmine API
 * @param log - Logger instance
 */
export function registerAttachmentTools(
  server: McpServer,
  dataProvider: DataProvider,
  log: any
) {
  // Register redmine_attachment_upload tool
  server.registerTool({
    name: "redmine_attachment_upload",
    description: "Upload a file and get a token for attaching it to an issue/wiki/etc.",
    schema: z.object({
      file_path: z.string().describe("Path to the file to upload"),
      filename: z.string().optional().describe("Optional custom filename (uses original filename if not specified)"),
      content_type: z.string().optional().describe("Optional content type (auto-detected if not specified)")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { file_path: string; filename?: string; content_type?: string }) => {
      try {
        log.info(`Executing redmine_attachment_upload with params:`, params);
        
        const filePath = params.file_path;
        const filename = params.filename;
        const contentType = params.content_type;
        
        log.debug(`Uploading file: ${filePath}`);
        
        // Check if uploadFile method exists on dataProvider
        if (!dataProvider.uploadFile) {
          throw new Error('uploadFile method is not available on the data provider');
        }
        
        const uploadResult = await dataProvider.uploadFile(filePath, filename, contentType);
        log.info(`File uploaded successfully, token: ${uploadResult.token}`);
        
        return uploadResult;
      } catch (error) {
        log.error(`Error in redmine_attachment_upload:`, error);
        throw new Error(`Failed to upload file: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_attachment_get tool
  server.registerTool({
    name: "redmine_attachment_get",
    description: "Get a specific attachment from Redmine",
    schema: z.object({
      attachment_id: z.number().describe("Attachment ID")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { attachment_id: number }) => {
      try {
        log.info(`Executing redmine_attachment_get with params:`, params);
        
        const attachmentId = params.attachment_id;
        
        log.debug(`Fetching attachment: ${attachmentId}`);
        
        // Check if getAttachment method exists on dataProvider
        if (!dataProvider.getAttachment) {
          throw new Error('getAttachment method is not available on the data provider');
        }
        
        const attachment = await dataProvider.getAttachment(attachmentId);
        log.info(`Found attachment: ${attachment.filename} (ID: ${attachment.id})`);
        
        return attachment;
      } catch (error) {
        log.error(`Error in redmine_attachment_get:`, error);
        throw new Error(`Failed to get attachment: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_attachment_download tool
  server.registerTool({
    name: "redmine_attachment_download",
    description: "Download the content of an attachment",
    schema: z.object({
      attachment_id: z.number().describe("Attachment ID"),
      destination_path: z.string().describe("Path where to save the attachment")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { attachment_id: number; destination_path: string }) => {
      try {
        log.info(`Executing redmine_attachment_download with params:`, params);
        
        const attachmentId = params.attachment_id;
        const destinationPath = params.destination_path;
        
        log.debug(`Downloading attachment ${attachmentId} to ${destinationPath}`);
        
        // Check if downloadAttachment method exists on dataProvider
        if (!dataProvider.downloadAttachment) {
          throw new Error('downloadAttachment method is not available on the data provider');
        }
        
        const success = await dataProvider.downloadAttachment(attachmentId, destinationPath);
        
        if (success) {
          log.info(`Downloaded attachment ${attachmentId} to ${destinationPath}`);
          return { success: true, message: `Attachment downloaded successfully to ${destinationPath}` };
        } else {
          log.warn(`Failed to download attachment ${attachmentId}`);
          return { success: false, message: `Failed to download attachment ${attachmentId}` };
        }
      } catch (error) {
        log.error(`Error in redmine_attachment_download:`, error);
        throw new Error(`Failed to download attachment: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_attachment_delete tool
  server.registerTool({
    name: "redmine_attachment_delete",
    description: "Delete an attachment from Redmine",
    schema: z.object({
      attachment_id: z.number().describe("Attachment ID")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { attachment_id: number }) => {
      try {
        log.info(`Executing redmine_attachment_delete with params:`, params);
        
        const attachmentId = params.attachment_id;
        
        log.debug(`Deleting attachment: ${attachmentId}`);
        
        // Check if deleteAttachment method exists on dataProvider
        if (!dataProvider.deleteAttachment) {
          throw new Error('deleteAttachment method is not available on the data provider');
        }
        
        const success = await dataProvider.deleteAttachment(attachmentId);
        
        if (success) {
          log.info(`Deleted attachment: ${attachmentId}`);
          return { success: true, message: `Attachment ${attachmentId} deleted successfully` };
        } else {
          log.warn(`Failed to delete attachment: ${attachmentId}`);
          return { success: false, message: `Failed to delete attachment ${attachmentId}` };
        }
      } catch (error) {
        log.error(`Error in redmine_attachment_delete:`, error);
        throw new Error(`Failed to delete attachment: ${(error as Error).message}`);
      }
    }
  });

  // Register redmine_issue_attachments tool
  server.registerTool({
    name: "redmine_issue_attachments",
    description: "Get all attachments for an issue",
    schema: z.object({
      issue_id: z.number().describe("Issue ID")
    }),
    // Fix: Add explicit type for params
    handler: async (params: { issue_id: number }) => {
      try {
        log.info(`Executing redmine_issue_attachments with params:`, params);
        
        const issueId = params.issue_id;
        
        log.debug(`Fetching attachments for issue: ${issueId}`);
        
        // Check if getIssueAttachments method exists on dataProvider
        if (!dataProvider.getIssueAttachments) {
          throw new Error('getIssueAttachments method is not available on the data provider');
        }
        
        const attachments = await dataProvider.getIssueAttachments(issueId);
        log.info(`Found ${attachments.length} attachments for issue ${issueId}`);
        
        return attachments;
      } catch (error) {
        log.error(`Error in redmine_issue_attachments:`, error);
        throw new Error(`Failed to get issue attachments: ${(error as Error).message}`);
      }
    }
  });
}
