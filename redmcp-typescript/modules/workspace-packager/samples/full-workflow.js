/**
 * full-workflow.js
 * Example script demonstrating the complete workflow:
 * 1. Create workspace package
 * 2. Load workspace into MCP agent environment
 * 3. Make changes
 * 4. Commit changes to GitHub
 */

const path = require('path');
const fs = require('fs-extra');
const os = require('os');
const {
  createWorkspacePackage,
  loadWorkspace,
  commitWorkspace,
  createPullRequest,
  cleanupWorkspace
} = require('../lib');

// Configuration
const sourceDir = process.argv[2] || path.join(__dirname, '../'); // Use module directory as example
const excludePatterns = ['node_modules', '.git', 'dist', 'build'];
const repository = 'user/repo';
const branch = 'feature/workspace-packager';
const commitMessage = 'Add workspace packager implementation';
const token = process.env.GITHUB_TOKEN; // GitHub token from environment variable
const agentId = `agent-${Date.now()}`;

async function main() {
  // Create temp directory for the package
  const outputDir = await fs.mkdtemp(path.join(os.tmpdir(), 'workspace-example-'));
  
  console.log(`\n=== STEP 1: Creating workspace package from ${sourceDir} ===\n`);
  
  // Create workspace package
  const packageResult = await createWorkspacePackage({
    sourceDir,
    outputDir,
    excludePatterns,
    customMetadata: {
      projectName: 'workspace-packager',
      description: 'Workspace packaging module for MCP agents',
      version: '0.1.0'
    }
  });
  
  console.log('Workspace package created successfully!');
  console.log(`Package path: ${packageResult.packagePath}`);
  console.log(`Workspace ID: ${packageResult.metadata.workspaceId}`);
  console.log(`File count: ${packageResult.metadata.fileCount}`);
  console.log(`Total size: ${formatSize(packageResult.metadata.totalSize)}`);
  
  console.log(`\n=== STEP 2: Loading workspace into MCP agent environment ===\n`);
  
  // Load workspace
  const workspace = await loadWorkspace({
    packagePath: packageResult.packagePath,
    agentId
  });
  
  console.log('Workspace loaded successfully!');
  console.log(`Workspace ID: ${workspace.id}`);
  console.log(`Mount point: ${workspace.mountPoint}`);
  
  console.log(`\n=== STEP 3: Making changes to workspace ===\n`);
  
  // Create a new README file
  const readmePath = 'README.example.md';
  await workspace.operations.writeFile(readmePath, `# Workspace Packager

## Example README

This file was created by the MCP agent to demonstrate the workspace packager module.

The workspace packager module allows MCP agents to:

1. Create isolated workspace packages from directory contents
2. Load these packages into secure environments
3. Make changes to files within the workspace
4. Commit changes back to GitHub repositories

This approach ensures that MCP agents can never access the real filesystem directly,
providing a secure way to work with files and directories.
`);
  
  console.log(`Created file: ${readmePath}`);
  
  // Create a simple TypeScript file
  const tsFilePath = 'example.ts';
  await workspace.operations.writeFile(tsFilePath, `/**
 * Example TypeScript file created by MCP agent
 */

interface ExampleInterface {
  name: string;
  value: number;
  description?: string;
}

class ExampleClass implements ExampleInterface {
  name: string;
  value: number;
  description?: string;
  
  constructor(name: string, value: number, description?: string) {
    this.name = name;
    this.value = value;
    this.description = description;
  }
  
  toString(): string {
    return \`\${this.name} (\${this.value})\${this.description ? ': ' + this.description : ''}\`;
  }
}

export default ExampleClass;
`);
  
  console.log(`Created file: ${tsFilePath}`);
  
  // Create a directory
  const dirPath = 'examples';
  await workspace.operations.mkdir(dirPath);
  
  // Create a file in the new directory
  const examplePath = path.join(dirPath, 'usage.js');
  await workspace.operations.writeFile(examplePath, `/**
 * Example usage of the workspace packager module
 */

const { createWorkspacePackage } = require('../lib');

async function example() {
  const result = await createWorkspacePackage({
    sourceDir: '/path/to/source',
    excludePatterns: ['node_modules']
  });
  
  console.log(\`Package created: \${result.packagePath}\`);
}

example().catch(console.error);
`);
  
  console.log(`Created directory: ${dirPath}`);
  console.log(`Created file: ${examplePath}`);
  
  if (token) {
    console.log(`\n=== STEP 4: Committing changes to GitHub (${repository}) ===\n`);
    
    // Commit changes to GitHub
    const commitResult = await commitWorkspace({
      workspace,
      repository,
      branch,
      message: commitMessage,
      token
    });
    
    if (commitResult.success) {
      console.log('Changes committed successfully!');
      console.log(`Commit SHA: ${commitResult.commitSha}`);
      console.log(`Commit URL: ${commitResult.url}`);
      
      // Create a pull request
      console.log('\nCreating pull request...');
      const prUrl = await createPullRequest({
        repository,
        title: 'Add workspace packager implementation',
        sourceBranch: branch,
        targetBranch: 'main',
        body: `This PR adds the workspace packager module for MCP agents.

The workspace packager:
- Creates isolated workspace packages from directory contents
- Loads these packages into secure environments for MCP agents
- Allows agents to make changes and commit them back to GitHub
- Ensures security by preventing direct filesystem access`,
        token
      });
      
      console.log(`Pull request created: ${prUrl}`);
    } else {
      console.error('Failed to commit changes:', commitResult.error?.message);
      console.log('Skipping pull request creation.');
    }
  } else {
    console.log('\nSkipping GitHub commit step (no token provided).');
    console.log('To commit changes, set the GITHUB_TOKEN environment variable.');
  }
  
  console.log(`\n=== STEP 5: Cleanup ===\n`);
  
  // Cleanup
  await cleanupWorkspace(workspace);
  await fs.remove(outputDir);
  
  console.log('Workspace cleaned up successfully!');
  console.log('Temporary directories removed.');
  
  console.log('\nWorkflow completed successfully!');
}

// Helper function to format file size
function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} bytes`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

// Run the script
main().catch(error => {
  console.error('Workflow failed:', error);
  process.exit(1);
});
