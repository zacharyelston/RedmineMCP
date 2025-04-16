/**
 * commit-workspace.js
 * Example script for committing workspace changes to GitHub
 */

const { loadWorkspace, commitWorkspace, createPullRequest } = require('../lib');

// Configuration
const packagePath = '/path/to/workspace-1234.tar.gz';
const agentId = 'agent-123';
const repository = 'user/repo';
const branch = 'feature/example-feature';
const commitMessage = 'Add example feature implementation';
const token = process.env.GITHUB_TOKEN; // GitHub token from environment variable

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
    
    // Make some changes to the workspace
    console.log('\nMaking changes to the workspace...');
    
    // Example: Create a new file
    await workspace.operations.writeFile('example.md', `# Example Feature
    
This is an example feature implementation created by the MCP agent.

## Features

- Feature 1: Example functionality
- Feature 2: Another example functionality

## Usage

\`\`\`javascript
const example = require('./example');
example.doSomething();
\`\`\`
`);

    // Example: Create a JavaScript file
    await workspace.operations.writeFile('example.js', `/**
 * Example module
 */

/**
 * Do something
 * @returns {string} Result message
 */
function doSomething() {
  console.log('Doing something...');
  return 'Something done!';
}

module.exports = {
  doSomething
};
`);
    
    console.log('Changes made successfully!');
    
    // Commit changes to GitHub
    console.log(`\nCommitting changes to GitHub repository ${repository} on branch ${branch}...`);
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
      
      // Create a pull request (optional)
      console.log('\nCreating pull request...');
      const prUrl = await createPullRequest({
        repository,
        title: 'Add example feature',
        sourceBranch: branch,
        targetBranch: 'main',
        body: 'This PR adds the example feature implementation.',
        token
      });
      
      console.log(`Pull request created: ${prUrl}`);
    } else {
      console.error('Failed to commit changes:', commitResult.error?.message);
    }
  } catch (error) {
    console.error('Failed to process workspace:', error.message);
    process.exit(1);
  }
}

// Run the script
main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
