# Redmine MCP Coding Standards

This document outlines the coding standards and best practices for the Redmine MCP project.

## TypeScript Files

### File Headers

All TypeScript files must include a standardized header that describes the file's purpose:

```typescript
/**
 * [Module Name]
 * 
 * [Brief description of what the module does]
 */
```

The header should be 5 lines or less and provide a clear indication of the file's purpose and functionality.

Example:
```typescript
/**
 * Time Tracking Client Module
 * 
 * Provides API methods for interacting with Redmine Time Entries
 */
```

### File Organization

The project follows a modular architecture with clear separation of concerns:

- `src/client/`: API client modules for Redmine resources (issues, projects, etc.)
- `src/core/`: Core functionality (error handling, logging, server setup)
- `src/lib/`: Utility libraries and implementations (RedmineClient, mock data)
- `src/tools/`: MCP tools implementation (connects API clients to MCP)
- `src/types/`: TypeScript type definitions

### Function Documentation

All public methods should include JSDoc comments with:

1. A description of what the function does
2. Parameter documentation with @param tags
3. Return value documentation with @returns tag
4. Optional @throws tag for documenting exceptions

Example:
```typescript
/**
 * Get a list of projects from Redmine
 * @param limit - Maximum number of projects to return
 * @param offset - Pagination offset
 * @param sort - Sort field and direction (field:direction)
 * @returns List of project objects
 * @throws Error if the API request fails
 */
async getProjects(limit: number = 25, offset: number = 0, sort: string = 'name:asc'): Promise<any[]> {
    // Implementation
}
```

## Error Handling

### Parameter Validation

All functions must validate their parameters before making API calls:

```typescript
if (!projectId) {
  const errorMessage = 'Project ID is required';
  console.error(`Error: ${errorMessage}`);
  
  // Log error to todo.yaml
  await this.logError({
    timestamp: new Date().toISOString(),
    level: 'error',
    component: 'ProjectsClient',
    operation: 'createProject',
    error_message: errorMessage,
    context: { name, identifier, parentId }
  });
  
  throw new Error(errorMessage);
}
```

### Error Logging

All errors should be logged with detailed context:

1. Error level (critical, error, warning, info)
2. Component name
3. Operation name
4. Error message
5. Context data (relevant parameters)
6. Stack trace when available
7. Recommended action

### Operation Verification

Critical operations like project transfers and subproject creation should be verified after execution:

```typescript
// Verify project creation
try {
  // Wait for database update
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Fetch the created entity to confirm it exists
  const createdProject = await this.getProject(identifier);
  
  // Enhanced verification
  if (parentId && (!createdProject.parent || createdProject.parent.id !== parentId)) {
    // Handle verification failure
  }
} catch (verifyError) {
  // Handle verification error
}
```

## Testing

### Unit Tests

All major functionality should have unit tests, focusing on:

1. Happy path (successful operation)
2. Parameter validation
3. Error handling
4. Edge cases

Tests should use mocks to avoid making actual API calls:

```typescript
// Mock axios
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

// Test example
test('should handle project transfer correctly', async () => {
  // Arrange (setup mocks)
  
  // Act (call the method)
  
  // Assert (verify behavior)
});
```

## Development Workflow

1. Always create a new branch for new features or bug fixes
2. Make small, atomic commits with clear messages
3. Use conventional commit format (feat:, fix:, docs:, etc.)
4. Build and test locally before submitting changes
5. Update documentation when changing functionality

## Implementation Notes

When implementing new features:

1. Follow existing patterns for consistency
2. Consider error cases and edge cases
3. Implement proper logging for operations
4. Verify operations after completion
5. Document any special handling or workarounds

## File Organization

Do NOT create issue-specific directories. Instead:

1. Store issue-related files directly in appropriate directories with descriptive filenames
2. Add implementation details directly as notes to Redmine issues
3. Follow the modular structure of the project
