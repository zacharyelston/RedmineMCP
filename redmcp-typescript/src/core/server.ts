/**
 * MCP Server setup for Redmine MCP
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as path from 'path';
import { fileURLToPath } from 'url';

import { setupLogging, logToTodo } from './logging.js';
import { DataProvider } from './types.js';
import { RedmineClient } from '../client/index.js';
import { MockDataProvider } from '../lib/mock/MockDataProvider.js';
import { registerAllTools } from '../tools/index.js';

// Get directory path for resolving todo.yaml
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const todoFilePath = path.resolve(__dirname, '../../../todo.yaml');

// Setup and start the MCP server
export async function setupServer(): Promise<void> {
  const startTime = new Date();
  const log = setupLogging();
  
  log.info(`Redmine MCP server starting at ${startTime.toISOString()}`);
  log.info(`Node.js version: ${process.version}`);
  
  // Get configuration from environment variables
  const redmineUrl = process.env.REDMINE_URL || 'http://localhost:3000';
  const redmineApiKey = process.env.REDMINE_API_KEY || '';
  const serverMode = process.env.SERVER_MODE || 'live';
  
  log.info(`Redmine URL: ${redmineUrl}`);
  log.debug(`Redmine API Key: ${redmineApiKey.substring(0, 4)}...`);
  log.info(`Server Mode: ${serverMode}`);
  log.info(`Todo file path: ${todoFilePath}`);
  
  // Create data provider based on server mode
  let dataProvider: DataProvider;
  
  if (serverMode === 'mock') {
    log.info('Using mock data provider');
    dataProvider = new MockDataProvider();
  } else {
    log.info('Using live Redmine client');
    const redmineClient = new RedmineClient(redmineUrl, redmineApiKey, todoFilePath);
    dataProvider = redmineClient;
    
    // Test connection to Redmine
    try {
      await redmineClient.testConnection();
      log.info('Successfully connected to Redmine');
    } catch (error) {
      log.error(`Failed to connect to Redmine: ${(error as Error).message}`);
      log.error('Switching to mock data provider as a fallback');
      dataProvider = new MockDataProvider();
      
      // Log connection error
      await logToTodo(todoFilePath, {
        timestamp: new Date().toISOString(),
        level: 'critical',
        component: 'MCP Server',
        operation: 'initialize',
        error_message: `Failed to connect to Redmine: ${(error as Error).message}`,
        stack_trace: (error as Error).stack,
        action: 'Check Redmine server availability and API key validity'
      });
    }
  }
  
  // Initialize MCP server
  const server = new McpServer({
    name: "Redmine MCP Server",
    version: "1.0.0",
  });
  
  // Register all tools with the server
  registerAllTools(server, dataProvider, log);
  
  // Start the server - connect using stdio transport
  const transport = new StdioServerTransport();
  await server.connect(transport);
  log.info('Redmine MCP server running - Connected to stdio transport');
  
  // Keep the process alive
  process.stdin.resume();
}
