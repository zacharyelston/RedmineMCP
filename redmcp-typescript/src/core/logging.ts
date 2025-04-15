/**
 * Logging utilities for Redmine MCP
 */
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'yaml';
import { ErrorLogEntry, Logger } from './types.js';

// Initialize logger
export function setupLogging(): Logger {
  return {
    info: (...args: any[]) => console.error('[INFO]', ...args),
    error: (...args: any[]) => console.error('[ERROR]', ...args),
    debug: (...args: any[]) => {
      if (process.env.LOG_LEVEL === 'debug') {
        console.error('[DEBUG]', ...args);
      }
    },
    warn: (...args: any[]) => console.error('[WARN]', ...args),
  };
}

// Function to log errors to todo.yaml
export async function logToTodo(todoFilePath: string, errorInfo: ErrorLogEntry): Promise<void> {
  try {
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
    
    // Add error entry - using the timestamp from the errorInfo object, not creating a new one
    todoData.errors.push(errorInfo);
    
    // Update timestamp
    todoData.updated = new Date().toISOString();
    
    // Write back to file
    fs.writeFileSync(todoFilePath, yaml.stringify(todoData), 'utf8');
    console.error(`Error logged to ${todoFilePath}`);
  } catch (logError) {
    console.error('Failed to log error to todo.yaml:', logError);
  }
}

// Function to create error issue in Redmine
export async function createErrorIssue(
  dataProvider: any, 
  errorInfo: ErrorLogEntry
): Promise<any> {
  try {
    // Create error issue in bugs project (ID 5)
    const subject = `Error: ${errorInfo.operation} - ${errorInfo.error_message.substring(0, 50)}...`;
    const description = `
## Automated Error Report

**Error Level:** ${errorInfo.level}
**Timestamp:** ${errorInfo.timestamp}
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
    
    console.error(`Created error issue: #${issue.id}`);
    return issue;
  } catch (issueError) {
    console.error('Failed to create error issue in Redmine:', issueError);
    return null;
  }
}
