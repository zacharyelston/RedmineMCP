# Workspace Packager Module

## Overview

The Workspace Packager module creates isolated workspace packages from directory contents, enabling Model Context Protocol (MCP) agents to work securely with file systems without requiring direct access to the host file system. It generates a tree representation of the directory structure, indexes file contents, packages everything in a tar archive with attached metadata, and provides tools for MCP agents to work in an isolated environment.

## Features

- **Directory Tree Generation**: Create a complete tree representation of directory structures
- **File Content Indexing**: Index file contents with metadata, sizes, and hashes
- **Secure Packaging**: Package directories into tar archives with embedded metadata
- **Isolated Workspace**: MCP agents work in controlled environments without file system access
- **GitHub Integration**: Commit workspace changes directly to GitHub repositories
- **Security**: Path traversal prevention, validation, and isolation

## How It Works

1. **Create Package**: A directory is scanned, indexed, and packaged with metadata
2. **Load Workspace**: The package is loaded into an isolated MCP agent environment
3. **Agent Operations**: The agent performs operations through a controlled API
4. **Commit Changes**: Changes are committed back to version control systems

This approach ensures MCP agents can never access the host file system directly, providing a secure way to work with files and directories.

## Installation

```bash
npm install --save @redmcp/workspace-packager
```

## Usage Examples

### Creating a Workspace Package

```javascript
const { createWorkspacePackage } = require('@redmcp/workspace-packager');

async function createPackage() {
  const result = await createWorkspacePackage({
    sourceDir: '/path/to/source',
    outputDir: '/path/to/output',
    excludePatterns: ['node_modules', '.git'],
    customMetadata: { 
      projectName: 'example-project',
      description: 'Example workspace package'
    }
  });
  
  console.log(`Package created: ${result.packagePath}`);
  console.log(`Workspace ID: ${result.metadata.workspaceId}`);
}
```

### Loading a Workspace Package

```javascript
const { loadWorkspace } = require('@redmcp/workspace-packager');

async function loadPackage() {
  const workspace = await loadWorkspace({
    packagePath: '/path/to/workspace.tar.gz',
    agentId: 'agent-123'
  });
  
  // List files in workspace
  const files = await workspace.operations.listDirectory('/');
  console.log('Files:', files);
  
  // Read a file
  const content = await workspace.operations.readFile('README.md');
  console.log('Content:', content.toString());
  
  // Write a file
  await workspace.operations.writeFile('example.js', 'console.log("Hello World");');
}
```

### Committing Changes to GitHub

```javascript
const { loadWorkspace, commitWorkspace } = require('@redmcp/workspace-packager');

async function commitChanges() {
  const workspace = await loadWorkspace({
    packagePath: '/path/to/workspace.tar.gz',
    agentId: 'agent-123'
  });
  
  // Make changes
  await workspace.operations.writeFile('example.md', '# Example\n\nThis is an example file.');
  
  // Commit changes
  const result = await commitWorkspace({
    workspace,
    repository: 'user/repo',
    branch: 'feature/example',
    message: 'Add example file',
    token: process.env.GITHUB_TOKEN
  });
  
  if (result.success) {
    console.log(`Changes committed: ${result.url}`);
  }
}
```

### Complete Workflow

```javascript
const { 
  createWorkspacePackage,
  loadWorkspace,
  commitWorkspace,
  cleanupWorkspace
} = require('@redmcp/workspace-packager');

async function workspaceWorkflow() {
  // Create package
  const packageResult = await createWorkspacePackage({
    sourceDir: '/path/to/source'
  });
  
  // Load workspace
  const workspace = await loadWorkspace({
    packagePath: packageResult.packagePath,
    agentId: 'agent-123'
  });
  
  // Make changes
  await workspace.operations.writeFile('example.md', '# Example\n\nThis is an example file.');
  
  // Commit changes
  const commitResult = await commitWorkspace({
    workspace,
    repository: 'user/repo',
    branch: 'feature/example',
    message: 'Add example file',
    token: process.env.GITHUB_TOKEN
  });
  
  // Cleanup
  await cleanupWorkspace(workspace);
}
```

## API Reference

### Main Functions

- `createWorkspacePackage(options)`: Create a workspace package from a directory
- `loadWorkspace(options)`: Load a workspace package for MCP agent use
- `commitWorkspace(options)`: Commit workspace changes to GitHub
- `cleanupWorkspace(workspace)`: Clean up workspace resources

### Utility Functions

- `generateTree(options)`: Generate a tree representation of a directory
- `indexFiles(options)`: Index files in a directory with metadata
- `createPackage(options)`: Create a tar archive package
- `extractPackage(packagePath, outputDir)`: Extract a workspace package
- `readPackageMetadata(packagePath)`: Read metadata from a package

## Security Considerations

- **Path Validation**: All file paths are validated to prevent path traversal attacks
- **Isolation**: MCP agents work in isolated environments with no access to the host file system
- **Content Validation**: File contents can be validated before operations
- **GitHub Token Security**: Token management for secure repository operations

## Benefits

- **Security**: MCP agents cannot access the real file system
- **Reproducibility**: Workspace packages contain complete environment context
- **Traceability**: All changes are tracked and can be committed to version control
- **Isolation**: Each agent works in a controlled, isolated environment
- **Portability**: Workspaces can be moved between different MCP environments

## License

MIT

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.
