/**
 * Error handling utilities for Redmine MCP
 */
import { Logger } from './types.js';
import { logToTodo } from './logging.js';
import * as path from 'path';
import { fileURLToPath } from 'url';

// Get directory path for resolving todo.yaml
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const todoFilePath = path.resolve(__dirname, '../../../todo.yaml');

// Handle process shutdown
export function handleShutdown(log: Logger): void {
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
    logToTodo(todoFilePath, {
      timestamp: new Date().toISOString(),
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
    logToTodo(todoFilePath, {
      timestamp: new Date().toISOString(),
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
}
