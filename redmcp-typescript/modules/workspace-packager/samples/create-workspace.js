/**
 * create-workspace.js
 * Example script for creating a workspace package
 */

const path = require('path');
const { createWorkspacePackage } = require('../lib');

// Configuration
const sourceDir = '/path/to/source';
const outputDir = '/path/to/output';
const excludePatterns = ['node_modules', '.git', 'dist', 'build'];
const customMetadata = {
  projectName: 'example-project',
  description: 'Example project for workspace packaging',
  version: '1.0.0',
  tags: ['example', 'demo', 'workspace'],
  author: 'MCP Team'
};

async function main() {
  console.log(`Creating workspace package from ${sourceDir}...`);
  
  try {
    // Create workspace package
    const result = await createWorkspacePackage({
      sourceDir,
      outputDir,
      excludePatterns,
      customMetadata
    });
    
    console.log('Workspace package created successfully!');
    console.log(`Package path: ${result.packagePath}`);
    console.log(`Workspace ID: ${result.metadata.workspaceId}`);
    console.log(`File count: ${result.metadata.fileCount}`);
    console.log(`Total size: ${formatSize(result.metadata.totalSize)}`);
    console.log(`Created at: ${result.metadata.createdAt}`);
  } catch (error) {
    console.error('Failed to create workspace package:', error.message);
    process.exit(1);
  }
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
  console.error('Unhandled error:', error);
  process.exit(1);
});
