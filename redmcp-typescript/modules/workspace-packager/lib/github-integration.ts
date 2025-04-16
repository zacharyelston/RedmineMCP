/**
 * github-integration.ts
 * Handles GitHub operations for committing workspace changes
 */

import { Octokit } from '@octokit/rest';
import fs from 'fs-extra';
import path from 'path';
import { WorkspaceEnvironment } from './workspace-loader';
import { glob } from 'glob';

export interface GitHubConfig {
  token: string;
  owner: string;
  repo: string;
}

export interface CommitOptions {
  workspace: WorkspaceEnvironment;
  repository: string; // Format: "owner/repo"
  branch: string;
  message: string;
  token?: string;
  force?: boolean;
  commitAllChanges?: boolean;
}

export interface CommitResult {
  success: boolean;
  commitSha?: string;
  url?: string;
  error?: Error;
}

/**
 * Parse GitHub repository string
 * @param repository - Repository string ("owner/repo")
 * @returns Owner and repo parts
 */
function parseRepository(repository: string): { owner: string; repo: string } {
  const parts = repository.split('/');
  
  if (parts.length !== 2) {
    throw new Error('Invalid repository format. Expected "owner/repo"');
  }
  
  return {
    owner: parts[0],
    repo: parts[1]
  };
}

/**
 * Commit workspace changes to GitHub
 * @param options - Commit options
 * @returns Promise resolving to commit result
 */
export async function commitWorkspace(options: CommitOptions): Promise<CommitResult> {
  const { 
    workspace, 
    repository, 
    branch, 
    message,
    force = false,
    commitAllChanges = true
  } = options;
  
  if (!workspace) {
    return {
      success: false,
      error: new Error('Workspace is required')
    };
  }
  
  // Get GitHub token
  const token = options.token || process.env.GITHUB_TOKEN;
  
  if (!token) {
    return {
      success: false,
      error: new Error('GitHub token is required')
    };
  }
  
  try {
    // Parse repository
    const { owner, repo } = parseRepository(repository);
    
    // Create Octokit instance
    const octokit = new Octokit({ auth: token });
    
    // Get the content base path
    const contentBasePath = path.join(workspace.mountPoint, 'content');
    
    // Check if branch exists
    let branchExists = false;
    let baseSha = '';
    
    try {
      const { data: branchData } = await octokit.repos.getBranch({
        owner,
        repo,
        branch
      });
      
      branchExists = true;
      baseSha = branchData.commit.sha;
    } catch (error) {
      // Branch doesn't exist, we'll create it
      branchExists = false;
      
      // Get default branch to use as base
      const { data: repoData } = await octokit.repos.get({
        owner,
        repo
      });
      
      const defaultBranch = repoData.default_branch;
      
      // Get the default branch commit SHA
      const { data: defaultBranchData } = await octokit.repos.getBranch({
        owner,
        repo,
        branch: defaultBranch
      });
      
      baseSha = defaultBranchData.commit.sha;
    }
    
    // Create tree entries from workspace files
    const files = await glob('**/*', {
      cwd: contentBasePath,
      nodir: true,
      dot: true,
    });
    
    const treeEntries = [];
    
    for (const file of files) {
      const content = await workspace.operations.readFile(file);
      
      treeEntries.push({
        path: file,
        mode: '100644', // Regular file
        type: 'blob',
        content: content.toString('utf-8')
      });
    }
    
    // Create tree
    const { data: tree } = await octokit.git.createTree({
      owner,
      repo,
      base_tree: baseSha,
      tree: treeEntries
    });
    
    // Create commit
    const { data: commit } = await octokit.git.createCommit({
      owner,
      repo,
      message,
      tree: tree.sha,
      parents: [baseSha]
    });
    
    // Create or update branch reference
    if (branchExists) {
      await octokit.git.updateRef({
        owner,
        repo,
        ref: `refs/heads/${branch}`,
        sha: commit.sha,
        force
      });
    } else {
      await octokit.git.createRef({
        owner,
        repo,
        ref: `refs/heads/${branch}`,
        sha: commit.sha
      });
    }
    
    return {
      success: true,
      commitSha: commit.sha,
      url: `https://github.com/${owner}/${repo}/commit/${commit.sha}`
    };
  } catch (error) {
    return {
      success: false,
      error: error as Error
    };
  }
}

/**
 * Create a pull request from workspace changes
 * @param options - Pull request options
 * @returns Promise resolving to PR URL
 */
export async function createPullRequest({
  repository,
  title,
  sourceBranch,
  targetBranch,
  body,
  token
}: {
  repository: string;
  title: string;
  sourceBranch: string;
  targetBranch: string;
  body?: string;
  token?: string;
}): Promise<string> {
  // Get GitHub token
  const authToken = token || process.env.GITHUB_TOKEN;
  
  if (!authToken) {
    throw new Error('GitHub token is required');
  }
  
  // Parse repository
  const { owner, repo } = parseRepository(repository);
  
  // Create Octokit instance
  const octokit = new Octokit({ auth: authToken });
  
  // Create pull request
  const { data: pullRequest } = await octokit.pulls.create({
    owner,
    repo,
    title,
    head: sourceBranch,
    base: targetBranch,
    body
  });
  
  return pullRequest.html_url;
}
