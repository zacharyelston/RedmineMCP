/**
 * index.ts
 * Main export file for workspace-packager module
 */

// Export types and functions from tree-generator
export { 
  generateTree, 
  formatTree, 
  TreeNode, 
  TreeGeneratorOptions 
} from './tree-generator';

// Export types and functions from file-indexer
export { 
  indexFiles, 
  FileIndex, 
  FileMetadata, 
  FileIndexerOptions 
} from './file-indexer';

// Export types and functions from packager
export { 
  createPackage, 
  readPackageMetadata, 
  extractPackage, 
  WorkspaceMetadata, 
  PackagerOptions, 
  PackageResult 
} from './packager';

// Export types and functions from workspace-loader
export { 
  loadWorkspace, 
  cleanupWorkspace, 
  WorkspaceEnvironment, 
  LoadWorkspaceOptions 
} from './workspace-loader';

// Export types and functions from github-integration
export { 
  commitWorkspace, 
  createPullRequest, 
  GitHubConfig, 
  CommitOptions, 
  CommitResult 
} from './github-integration';

// Import necessary modules
import { generateTree, TreeGeneratorOptions } from './tree-generator';
import { indexFiles, FileIndexerOptions } from './file-indexer';
import { createPackage, PackagerOptions, PackageResult } from './packager';
import { loadWorkspace, WorkspaceEnvironment, LoadWorkspaceOptions } from './workspace-loader';
import { commitWorkspace, CommitOptions, CommitResult } from './github-integration';

/**
 * Create a workspace package from a directory
 * This is a convenience function that combines tree generation, file indexing, and packaging
 * @param options - Options for creating workspace package
 * @returns Promise resolving to package result
 */
export async function createWorkspacePackage(options: PackagerOptions): Promise<PackageResult> {
  const { sourceDir, excludePatterns = [] } = options;
  
  // Generate directory tree
  const tree = await generateTree({
    rootDir: sourceDir,
    excludePatterns
  });
  
  // Index files
  const index = await indexFiles({
    rootDir: sourceDir,
    excludePatterns
  });
  
  // Create package
  return createPackage({
    ...options,
    fileIndex: index,
    directoryTree: tree
  });
}

/**
 * Complete workflow: Create workspace package, load it, and commit to GitHub
 * @param options - Workflow options
 * @returns Promise resolving to workflow result
 */
export async function createAndCommitWorkspace(options: {
  sourceDir: string;
  excludePatterns?: string[];
  repository: string;
  branch: string;
  message: string;
  token?: string;
  agentId?: string;
}): Promise<{
  packageResult: PackageResult;
  workspace: WorkspaceEnvironment;
  commitResult: CommitResult;
}> {
  const { 
    sourceDir, 
    excludePatterns = [],
    repository, 
    branch, 
    message, 
    token,
    agentId = 'default-agent'
  } = options;
  
  // Create workspace package
  const packageResult = await createWorkspacePackage({
    sourceDir,
    excludePatterns
  });
  
  // Load workspace
  const workspace = await loadWorkspace({
    packagePath: packageResult.packagePath,
    agentId
  });
  
  // Commit to GitHub
  const commitResult = await commitWorkspace({
    workspace,
    repository,
    branch,
    message,
    token
  });
  
  return {
    packageResult,
    workspace,
    commitResult
  };
}
