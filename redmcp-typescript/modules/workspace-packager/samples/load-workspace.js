/**
 * load-workspace.js
 * Example script for loading a workspace package for MCP agent use
 */

const { loadWorkspace, cleanupWorkspace } = require('../lib');

// Configuration
const packagePath = '/path/to/workspace-1234.tar.gz';
const agentId = 'agent-123';

async function main() {
  console.log(`Loading workspace package from ${packagePath}...`);
  
  try {
    // Load workspace
    const workspace = await loadWorkspace({
      packagePath,
      agentId
    });
    
    console.log('Workspace loaded successfully!');
    console.log(`Workspace ID: ${workspace.id}`);
    console.log(`Mount point: ${workspace.mountPoint}`);
    console.log(`File count: ${workspace.metadata.fileCount}`);
    
    // Example: List files in the workspace root
    const files = await workspace.operations.listDirectory('/');
    console.log('\nFiles in workspace root:');
    for (const file of files) {
      console.log(`- ${file}`);
    }
    
    // Example: Read a file from the workspace
    const readFilePath = 'README.md';
    if (await workspace.operations.exists(readFilePath)) {
      const content = await workspace.operations.readFile(readFilePath);
      console.log(`\nContents of ${readFilePath}:`);
      console.log('-----------------------------------');
      console.log(content.toString('utf-8').slice(0, 200) + '...');
      console.log('-----------------------------------');
    }
    
    // Example: Write a file to the workspace
    const writeFilePath = 'example.txt';
    await workspace.operations.writeFile(writeFilePath, 'This is an example file created by the MCP agent.');
    console.log(`\nCreated file: ${writeFilePath}`);
    
    // Example: Get directory tree
    const tree = await workspace.operations.getTree();
    console.log('\nDirectory tree structure (root node only):');
    console.log(JSON.stringify(tree, null, 2).slice(0, 200) + '...');
    
    // Cleanup
    console.log('\nCleaning up workspace...');
    await cleanupWorkspace(workspace);
    console.log('Workspace cleaned up successfully!');
  } catch (error) {
    console.error('Failed to load workspace:', error.message);
    process.exit(1);
  }
}

// Run the script
main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
