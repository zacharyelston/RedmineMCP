/**
 * RedmineClient.ts Test Suite
 * 
 * This test suite verifies the functionality of the RedmineClient.ts implementation,
 * particularly focusing on issue transfers between projects and error handling.
 */

// Import necessary modules for testing
// Note: Jest needs to be installed with: npm install --save-dev jest ts-jest @types/jest
import axios from 'axios';
import { RedmineClient } from '../RedmineClient.js';

// Mock axios to avoid actual API calls
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

// Mock console.error to avoid cluttering test output
jest.spyOn(console, 'error').mockImplementation(() => {});

describe('RedmineClient', () => {
  // Setup before each test
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Setup axios create to return a mocked instance
    mockedAxios.create.mockReturnValue(mockedAxios as any);
  });

  describe('Constructor', () => {
    test('should initialize with the provided baseUrl and apiKey', () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      
      // Act
      const client = new RedmineClient(baseUrl, apiKey);
      
      // Assert
      expect(mockedAxios.create).toHaveBeenCalledWith({
        baseURL: baseUrl,
        headers: {
          'X-Redmine-API-Key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json, application/xml, text/xml, */*'
        }
      });
    });
  });

  describe('updateIssue', () => {
    test('should handle project transfer correctly by preserving issue data', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const issueId = 123;
      const newProjectId = 456;
      
      // Mock the current issue data
      const mockCurrentIssue = {
        id: issueId,
        project: { id: 789, name: 'Original Project' },
        tracker: { id: 1, name: 'Bug' },
        status: { id: 1, name: 'New' },
        priority: { id: 2, name: 'Normal' },
        subject: 'Original Subject',
        description: 'Original Description'
      };
      
      // Mock axios get response for current issue data
      mockedAxios.get.mockResolvedValueOnce({
        data: { issue: mockCurrentIssue }
      });
      
      // Mock axios put response for update
      mockedAxios.put.mockResolvedValueOnce({
        status: 200,
        data: { issue: { ...mockCurrentIssue, project: { id: newProjectId, name: 'New Project' } } }
      });
      
      // Create client and call the updateIssue method with project_id
      const client = new RedmineClient(baseUrl, apiKey);
      const result = await client.updateIssue(issueId, { project_id: newProjectId });
      
      // Assert
      // 1. Should first call get to retrieve current issue data
      expect(mockedAxios.get).toHaveBeenCalledWith(`/issues/${issueId}.json`, expect.any(Object));
      
      // 2. Should then call put with a complete payload including all required fields
      expect(mockedAxios.put).toHaveBeenCalledWith(
        `/issues/${issueId}.json`,
        {
          issue: {
            project_id: newProjectId,
            tracker_id: mockCurrentIssue.tracker.id,
            status_id: mockCurrentIssue.status.id,
            priority_id: mockCurrentIssue.priority.id,
            subject: mockCurrentIssue.subject,
            description: mockCurrentIssue.description,
            notes: expect.stringContaining(`Moved to project ID: ${newProjectId}`)
          }
        }
      );
      
      // 3. Should return true for successful update
      expect(result).toBe(true);
    });

    test('should handle regular updates without project change differently', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const issueId = 123;
      const updateParams = { 
        subject: 'Updated Subject',
        description: 'Updated Description'
      };
      
      // Mock axios put response for update
      mockedAxios.put.mockResolvedValueOnce({
        status: 200,
        data: {}
      });
      
      // Create client and call the updateIssue method without project_id
      const client = new RedmineClient(baseUrl, apiKey);
      const result = await client.updateIssue(issueId, updateParams);
      
      // Assert
      // 1. Should not call get to retrieve current issue data
      expect(mockedAxios.get).not.toHaveBeenCalled();
      
      // 2. Should call put with just the update parameters
      expect(mockedAxios.put).toHaveBeenCalledWith(
        `/issues/${issueId}.json`,
        {
          issue: updateParams
        }
      );
      
      // 3. Should return true for successful update
      expect(result).toBe(true);
    });

    test('should handle errors during project transfer correctly', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const issueId = 123;
      const newProjectId = 456;
      
      // Mock the current issue data
      const mockCurrentIssue = {
        id: issueId,
        project: { id: 789, name: 'Original Project' },
        tracker: { id: 1, name: 'Bug' },
        status: { id: 1, name: 'New' },
        priority: { id: 2, name: 'Normal' },
        subject: 'Original Subject',
        description: 'Original Description'
      };
      
      // Mock axios get response for current issue data
      mockedAxios.get.mockResolvedValueOnce({
        data: { issue: mockCurrentIssue }
      });
      
      // Mock axios put to throw an error
      const errorResponse = {
        response: {
          status: 422,
          data: {
            errors: ['Project is invalid']
          }
        }
      };
      mockedAxios.put.mockRejectedValueOnce(errorResponse);
      
      // Create client and prepare to catch the error
      const client = new RedmineClient(baseUrl, apiKey);
      
      // Act & Assert
      await expect(
        client.updateIssue(issueId, { project_id: newProjectId })
      ).rejects.toThrow('Failed to update Redmine issue with project change');
      
      // Verify axios call sequence
      expect(mockedAxios.get).toHaveBeenCalledWith(`/issues/${issueId}.json`, expect.any(Object));
      expect(mockedAxios.put).toHaveBeenCalledWith(`/issues/${issueId}.json`, expect.any(Object));
    });
  });

  describe('createIssue', () => {
    test('should create issue with all required parameters', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const projectId = 1;
      const subject = 'Test Issue';
      const description = 'Test Description';
      const trackerId = 1;
      const statusId = 1;
      const priorityId = 2;
      
      // Mock axios post response
      const mockCreatedIssue = {
        id: 123,
        project: { id: projectId, name: 'Project' },
        tracker: { id: trackerId, name: 'Bug' },
        status: { id: statusId, name: 'New' },
        priority: { id: priorityId, name: 'Normal' },
        subject: subject,
        description: description
      };
      
      mockedAxios.post.mockResolvedValueOnce({
        status: 201,
        data: { issue: mockCreatedIssue }
      });
      
      // Create client and call createIssue
      const client = new RedmineClient(baseUrl, apiKey);
      const result = await client.createIssue(
        projectId,
        subject,
        description,
        trackerId,
        statusId,
        priorityId
      );
      
      // Assert
      // 1. Should call post with properly nested issue object
      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/issues.json',
        {
          issue: {
            project_id: projectId,
            subject: subject,
            description: description,
            tracker_id: trackerId,
            status_id: statusId,
            priority_id: priorityId
          }
        },
        expect.any(Object)
      );
      
      // 2. Should return the created issue
      expect(result).toEqual(mockCreatedIssue);
    });

    test('should handle missing required parameters', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const client = new RedmineClient(baseUrl, apiKey);
      
      // Act & Assert - missing projectId
      await expect(
        client.createIssue(0, 'Test Subject')
      ).rejects.toThrow('Project ID is required');
      
      // Act & Assert - missing subject
      await expect(
        client.createIssue(1, '')
      ).rejects.toThrow('Subject is required');
      
      // Act & Assert - missing subject (null)
      await expect(
        client.createIssue(1, null as any)
      ).rejects.toThrow('Subject is required');
    });

    test('should handle API errors correctly', async () => {
      // Arrange
      const baseUrl = 'http://example.com';
      const apiKey = 'test-api-key';
      const projectId = 1;
      const subject = 'Test Issue';
      
      // Mock axios post to throw an error
      const errorResponse = {
        response: {
          status: 422,
          data: {
            errors: ['Project is invalid']
          }
        }
      };
      mockedAxios.post.mockRejectedValueOnce(errorResponse);
      
      // Create client and prepare to catch the error
      const client = new RedmineClient(baseUrl, apiKey);
      
      // Act & Assert
      await expect(
        client.createIssue(projectId, subject)
      ).rejects.toThrow('Failed to create Redmine issue');
    });
  });

  // Add more test cases for other methods (getProjects, getIssue, etc.)
});
