# Implementation Plan for Issue #93: Modularize Redmine MCP Codebase

## Overview

Issue #93 requires restructuring the Redmine MCP codebase to make it more modular and maintainable. We need to complete the modularization of the codebase according to the specifications provided in the issue.

## Current Status

- Initial modularization has already started:
  - Directory structure for client, core, and tools modules exists
  - Some module files are in place (base.ts, issues.ts, projects.ts in client directory)
  - Core modules (errors.ts, logging.ts, server.ts, types.ts) exist
  - Some tool modules (issueTools.ts, issueRelations.ts) exist
  - The index.ts file already imports from the modular structure
  - The client/index.ts file already exports a modular RedmineClient class

- Main areas requiring work:
  1. Moving logging from index.ts to core/logging.ts
  2. Moving error handling from index.ts to core/errors.ts
  3. Moving server setup from index.ts to core/server.ts
  4. Creating missing client modules (wiki.ts, time.ts, attachments.ts, metadata.ts)
  5. Creating missing tool modules (projects.ts, wiki.ts, time.ts, attachments.ts, metadata.ts)
  6. Implementing a proper tool registration system
  7. Ensuring all interfaces and types are properly defined

## Implementation Steps

### 1. Core Module Updates

1. **Update core/logging.ts**
   - Move the logging code from index.ts to core/logging.ts
   - Create proper interfaces for the logger
   - Export a setupLogging function

2. **Update core/errors.ts**
   - Move error handling code from index.ts to core/errors.ts
   - Create functions for error logging to todo.yaml
   - Create functions for issue creation
   - Export a handleShutdown function

3. **Update core/server.ts**
   - Move server setup code from index.ts to core/server.ts
   - Create a setupServer function to initialize the MCP server
   - Import tool registration from the tools module

4. **Update core/types.ts**
   - Define common interfaces and types used across modules
   - Define error types and levels
   - Define tool parameter types

### 2. Client Module Updates

1. **Create missing client modules**
   - Create wiki.ts for wiki-related API methods
   - Create time.ts for time tracking API methods
   - Create attachments.ts for attachment API methods
   - Create metadata.ts for API methods for statuses, trackers, etc.

2. **Update client/index.ts**
   - Import and compose all client modules
   - Update DataProvider interface to include new methods

### 3. Tools Module Updates

1. **Create missing tool modules**
   - Create projects.ts for project-related tools
   - Create wiki.ts for wiki-related tools
   - Create time.ts for time tracking tools
   - Create attachments.ts for attachment tools
   - Create metadata.ts for tools for statuses, trackers, etc.

2. **Update tools/index.ts**
   - Implement a proper tool registration system
   - Import and register all tool modules

### 4. Testing

1. **Create test structure**
   - Set up tests for core modules
   - Set up tests for client modules
   - Set up tests for tool modules

2. **Create test utilities**
   - Create mock data and services
   - Create test helpers

## Implementation Order

To ensure a systematic approach and validate each step along the way, we'll implement the changes in the following order:

1. Core module updates (logging.ts, errors.ts, types.ts, server.ts)
2. Client module updates (create missing modules, update index.ts)
3. Tools module updates (create missing modules, update index.ts)
4. Testing structure setup

## Validation Plan

After each step, we'll validate our changes to ensure they work correctly:

1. After core module updates:
   - Check that the server still starts correctly
   - Verify logging works properly
   - Verify error handling works properly

2. After client module updates:
   - Test basic client functionality
   - Verify API calls work correctly
   - Check that data is returned as expected

3. After tools module updates:
   - Test each tool separately
   - Verify tool registration works correctly
   - Check that tools can be called from the MCP server

4. After testing structure setup:
   - Run all tests to verify everything works correctly
   - Check test coverage
   - Ensure tests are properly structured

## Estimated Timeline

1. Core module updates: 1-2 hours
2. Client module updates: 2-3 hours
3. Tools module updates: 2-3 hours
4. Testing structure setup: 1-2 hours

Total estimated time: 6-10 hours
