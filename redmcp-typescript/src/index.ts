#!/usr/bin/env node
/**
 * Redmine MCP Server - Connect Claude Desktop to Redmine
 * Using the Model Context Protocol
 * 
 * MODULAR VERSION - ISSUE #93
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { config } from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import * as fs from 'fs';
import * as yaml from 'yaml';

// Import from client and tools modules using the modular structure
import { RedmineClient, DataProvider } from './client/index.js';
import { registerAllTools } from './tools/index.js';
import { MockDataProvider } from './lib/mock/MockDataProvider.js';

// Configure environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, '../.env');
config({ path: envPath });

// Initialize logger - always output to stderr for MCP
const log = {
  info: (...args: any[]) => console.error('[INFO]', ...args),
  error: (...args: any[]) => console.error('[ERROR]', ...args),
  debug: (...args: any[]) => {
    if (process.env.LOG_LEVEL === 'debug') {
      console.error('[DEBUG]', ...args);
    }
  },
  warn: (...args: any[]) => console.error('[WARN]', ...args),
};

// Function to log errors to todo.yaml
async function logToTodo(errorInfo: any) {
  try {
    const todoFilePath = path.resolve(__dirname, '../../todo.yaml');
    let todoData: any = {};
    
    // Read current todo.yaml if it exists
    try {
      if (fs.existsSync(todoFilePath)) {
        const todoContent = fs.readFileSync(todoFilePath, 'utf8');
        if (todoContent.trim().startsWith('{')) {
          // If file is in JSON format
          todoData = JSON.parse(todoContent);
        } else {
          // If file is in YAML format
          todoData = yaml.parse(todoContent);
        }
      }
    } catch (readError) {
      // If parsing fails, create a new structure
      todoData = {
        version: "1.0.0",
        updated: new Date().toISOString(),
        tasks: [],
        errors: []
      };
    }
    
    // Initialize errors array if it doesn't exist
    if (!todoData.errors) {
      todoData.errors = [];
    }
    
    // Add error entry
    todoData.errors.push({
      timestamp: new Date().toISOString(),
      ...errorInfo
    });
    
    // Update timestamp
    todoData.updated = new Date().toISOString();
    
    // Write back to file
    fs.writeFileSync(todoFilePath, yaml.stringify(todoData), 'utf8');
    log.debug(`Error logged to ${todoFilePath}`);
  } catch (logError) {
    log.error('Failed to log error to todo.yaml:', logError);
  }
}

// Function to create error issue in Redmine
async function createErrorIssue(dataProvider: DataProvider, errorInfo: any) {
  try {
    // Create error issue in bugs project (ID 5)
    const subject = `Error: ${errorInfo.operation} - ${errorInfo.error_message.substring(0, 50)}...`;
    const description = `
## Automated Error Report

**Error Level:** ${errorInfo.level}
**Timestamp:** ${errorInfo.timestamp || new Date().toISOString()}
**Component:** ${errorInfo.component}
**Operation:** ${errorInfo.operation}

### Error Details
\`\`\`
${errorInfo.error_message}
\`\`\`

### Stack Trace
\`\`\`
${errorInfo.stack_trace || 'No stack trace available'}
\`\`\`

### Context
\`\`\`json
${JSON.stringify(errorInfo.context || {}, null, 2)}
\`\`\`

### Recommended Action
${errorInfo.action || 'Investigate and fix the issue'}
`;

    // Map error level to priority
    const priorityMap: Record<string, number> = {
      critical: 4, // Urgent
      error: 3,    // High
      warning: 2,  // Normal
      info: 1      // Low
    };
    
    const priorityId = priorityMap[errorInfo.level] || 2;
    
    const issue = await dataProvider.createIssue(
      5, // bugs project ID
      subject,
      description,
      1, // Bug tracker ID
      1, // New status ID
      priorityId
    );
    
    log.debug(`Created error issue: #${issue.id}`);
    return issue;
  } catch (issueError) {
    log.error('Failed to create error issue in Redmine:', issueError);
    return null;
  }
}

// Main execution function
async function main() {
  const startTime = new Date();
  log.info(`Redmine MCP server starting at ${startTime.toISOString()}`);
  log.info(`Node.js version: ${process.version}`);
  
  try {
    // Get configuration from environment variables
    const redmineUrl = process.env.REDMINE_URL || 'http://localhost:3000';
    const redmineApiKey = process.env.REDMINE_API_KEY || '';
    const serverMode = process.env.SERVER_MODE || 'live';
    
    log.info(`Redmine URL: ${redmineUrl}`);
    log.debug(`Redmine API Key: ${redmineApiKey.substring(0, 4)}...`);
    log.info(`Server Mode: ${serverMode}`);
    
    // Resolve path to todo.yaml
    const todoFilePath = path.resolve(__dirname, '../../todo.yaml');
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
        await logToTodo({
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
    
    // Register all tools using the modular approach
    registerAllTools(server, dataProvider, log);
    
    // Start the server - connect using stdio transport
    const transport = new StdioServerTransport();
    await server.connect(transport);
    log.info('Redmine MCP server running - Connected to stdio transport');
    
    // Keep the process alive
    process.stdin.resume();
    
  } catch (error) {
    log.error('Error starting Redmine MCP server:', error);
    
    // Log critical error to todo.yaml
    await logToTodo({
      level: 'critical',
      component: 'MCP Server',
      operation: 'startup',
      error_message: `Failed to start Redmine MCP server: ${(error as Error).message}`,
      stack_trace: (error as Error).stack,
      action: 'Check server configuration and restart'
    });
    
    process.exit(1);
  }
}

// Handle process signals
process.on('SIGINT', () => {
  log.info('Received SIGINT signal, shutting down...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  log.info('Received SIGTERM signal, shutting down...');
  process.exit(0);
});

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  log.error('Uncaught exception:', error);
  
  // Log uncaught exception to todo.yaml
  logToTodo({
    level: 'critical',
    component: 'MCP Server',
    operation: 'uncaughtException',
    error_message: `Uncaught exception: ${error.message}`,
    stack_trace: error.stack,
    action: 'Check server code for bugs and restart'
  }).catch(logError => {
    console.error('Failed to log uncaught exception to todo.yaml:', logError);
  });
  
  // Don't exit process on uncaught exceptions to maintain MCP connection
});

process.on('unhandledRejection', (reason, promise) => {
  log.error('Unhandled rejection at:', promise, 'reason:', reason);
  
  // Log unhandled rejection to todo.yaml
  logToTodo({
    level: 'critical',
    component: 'MCP Server',
    operation: 'unhandledRejection',
    error_message: `Unhandled rejection: ${reason instanceof Error ? reason.message : String(reason)}`,
    stack_trace: reason instanceof Error ? reason.stack : 'No stack trace available',
    action: 'Check server code for promise handling bugs'
  }).catch(logError => {
    console.error('Failed to log unhandled rejection to todo.yaml:', logError);
  });
  
  // Don't exit process on unhandled rejections to maintain MCP connection
});

// Start the server
main().catch(error => {
  log.error('Error in main function:', error);
  
  // Try to log the error to todo.yaml
  try {
    const todoFilePath = path.resolve(__dirname, '../../todo.yaml');
    const errorEntry = {
      timestamp: new Date().toISOString(),
      level: 'critical',
      component: 'MCP Server',
      operation: 'main',
      error_message: `Error in main function: ${error.message}`,
      stack_trace: error.stack,
      action: 'Investigate server startup issue'
    };
    
    let todoData: any = {};
    try {
      if (fs.existsSync(todoFilePath)) {
        const todoContent = fs.readFileSync(todoFilePath, 'utf8');
        if (todoContent.trim().startsWith('{')) {
          todoData = JSON.parse(todoContent);
        } else {
          todoData = yaml.parse(todoContent);
        }
      }
    } catch {
      todoData = {
        version: "1.0.0",
        updated: new Date().toISOString(),
        tasks: [],
        errors: []
      };
    }
    
    if (!todoData.errors) {
      todoData.errors = [];
    }
    
    todoData.errors.push(errorEntry);
    todoData.updated = new Date().toISOString();
    
    fs.writeFileSync(todoFilePath, yaml.stringify(todoData), 'utf8');
  } catch (logError) {
    console.error('Failed to log main function error to todo.yaml:', logError);
  }
  
  process.exit(1);
});
