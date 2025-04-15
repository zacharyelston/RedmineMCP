/**
 * Tests for Redmine client modules
 */
import { jest } from '@jest/globals';
import { RedmineClient } from '../../src/client/index.js';

// Mock axios to avoid actual API calls
jest.mock('axios', () => ({
  create: jest.fn(() => ({
    get: jest.fn(),
    post: jest.fn(),
    put: jest.fn(),
    delete: jest.fn(),
    interceptors: {
      request: {
        use: jest.fn()
      }
    }
  }))
}));

// Mock fs
jest.mock('fs', () => ({
  existsSync: jest.fn(() => true),
  readFileSync: jest.fn(() => '{}'),
  writeFileSync: jest.fn(),
  createReadStream: jest.fn(),
  createWriteStream: jest.fn(() => ({
    on: jest.fn(),
    pipe: jest.fn()
  }))
}));

describe('RedmineClient', () => {
  let client;
  
  beforeEach(() => {
    // Create a new client instance for each test
    client = new RedmineClient('http://localhost:3000', 'test-api-key', 'test-todo.yaml');
  });
  
  describe('Basic functionality', () => {
    test('client is properly initialized', () => {
      expect(client).toBeInstanceOf(RedmineClient);
    });
    
    test('client has expected methods', () => {
      // Core methods
      expect(typeof client.testConnection).toBe('function');
      expect(typeof client.getCurrentUser).toBe('function');
      
      // Project methods
      expect(typeof client.getProjects).toBe('function');
      expect(typeof client.getProject).toBe('function');
      expect(typeof client.createProject).toBe('function');
      
      // Issue methods
      expect(typeof client.getIssues).toBe('function');
      expect(typeof client.getIssue).toBe('function');
      expect(typeof client.createIssue).toBe('function');
      expect(typeof client.updateIssue).toBe('function');
      
      // Wiki methods
      expect(typeof client.getWikiPages).toBe('function');
      expect(typeof client.getWikiPage).toBe('function');
      expect(typeof client.createOrUpdateWikiPage).toBe('function');
      expect(typeof client.deleteWikiPage).toBe('function');
      
      // Time tracking methods
      expect(typeof client.getTimeEntries).toBe('function');
      expect(typeof client.getTimeEntry).toBe('function');
      expect(typeof client.createTimeEntry).toBe('function');
      expect(typeof client.updateTimeEntry).toBe('function');
      expect(typeof client.deleteTimeEntry).toBe('function');
      
      // Attachment methods
      expect(typeof client.uploadFile).toBe('function');
      expect(typeof client.getAttachment).toBe('function');
      expect(typeof client.downloadAttachment).toBe('function');
      expect(typeof client.deleteAttachment).toBe('function');
      
      // Metadata methods
      expect(typeof client.getIssueStatuses).toBe('function');
      expect(typeof client.getTrackers).toBe('function');
      expect(typeof client.getIssuePriorities).toBe('function');
      expect(typeof client.getTimeEntryActivities).toBe('function');
      expect(typeof client.getUsers).toBe('function');
      expect(typeof client.getIssueCategories).toBe('function');
      expect(typeof client.getCustomFields).toBe('function');
    });
  });
  
  // Add more specific tests for each module
  // These would test the specific functionality of each module
  // but for now we're just validating the structure
});
