/**
 * workspace-loader.ts
 * Loads packaged workspace for MCP agent use
 */

import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { v4 as uuidv4 } from 'uuid';
import { WorkspaceMetadata, extractPackage } from './packager';
import { FileIndex } from './file-indexer';
import { TreeNode } from './tree-generator';

export interface WorkspaceEnvironment {
  id: string;
  mountPoint: string;
  metadata: WorkspaceMetadata;
  fileIndex?: FileIndex;
  directoryTree?: TreeNode;
  operations: {
    readFile: (filePath: string) => Promise<Buffer>;
    writeFile: (filePath: string, content: Buffer | string) => Promise<void>;
    listDirectory: (dirPath: string) => Promise<string[]>;
    exists: (path: string) => Promise<boolean>;
    stat: (path: string) => Promise<fs.Stats>;
    mkdir: (dirPath: string) => Promise<void>;
    remove: (path: string) => Promise<void>;
    copy: (src: string, dest: string) => Promise<void>;
    move: (src: string, dest: string) => Promise<void>;
    getTree: () => Promise<TreeNode>;
    getIndex: () => Promise<FileIndex>;
  };
}

export interface LoadWorkspaceOptions {
  packagePath: string;
  agentId: string;
  mountPoint?: string;
}

/**
 * Validate path is within workspace
 * @param basePath - Workspace base path
 * @param targetPath - Path to validate
 * @returns Normalized path if valid, throws error otherwise
 */
function validatePath(basePath: string, targetPath: string): string {
  const normalizedPath = path.normalize(path.join(basePath, targetPath));
  
  if (!normalizedPath.startsWith(basePath)) {
    throw new Error(`Path traversal attempt detected. Access denied to: ${targetPath}`);
  }
  
  return normalizedPath;
}

/**
 * Load a workspace package for MCP agent use
 * @param options - Load workspace options
 * @returns Promise resolving to workspace environment
 */
export async function loadWorkspace(options: LoadWorkspaceOptions): Promise<WorkspaceEnvironment> {
  const { packagePath, agentId } = options;
  
  if (!await fs.pathExists(packagePath)) {
    throw new Error(`Package not found: ${packagePath}`);
  }
  
  // Extract package to temp directory
  const extractResult = await extractPackage(packagePath);
  const { extractPath, metadata } = extractResult;
  
  // Content directory is where the actual files are stored
  const contentBasePath = path.join(extractPath, 'content');
  
  // Mount point (virtual path for the agent)
  const mountPoint = options.mountPoint || `/workspace-${metadata.workspaceId}`;
  
  // Read file index if it exists
  let fileIndex: FileIndex | undefined;
  const indexPath = path.join(extractPath, 'workspace-index.json');
  if (await fs.pathExists(indexPath)) {
    fileIndex = await fs.readJson(indexPath) as FileIndex;
  }
  
  // Read directory tree if it exists
  let directoryTree: TreeNode | undefined;
  const treePath = path.join(extractPath, 'workspace-tree.json');
  if (await fs.pathExists(treePath)) {
    directoryTree = await fs.readJson(treePath) as TreeNode;
  }
  
  // Create workspace environment with operations
  const workspace: WorkspaceEnvironment = {
    id: metadata.workspaceId,
    mountPoint,
    metadata,
    fileIndex,
    directoryTree,
    operations: {
      // Read file from workspace
      readFile: async (filePath: string): Promise<Buffer> => {
        const targetPath = validatePath(contentBasePath, filePath);
        return fs.readFile(targetPath);
      },
      
      // Write file to workspace
      writeFile: async (filePath: string, content: Buffer | string): Promise<void> => {
        const targetPath = validatePath(contentBasePath, filePath);
        const targetDir = path.dirname(targetPath);
        
        if (!await fs.pathExists(targetDir)) {
          await fs.mkdirp(targetDir);
        }
        
        return fs.writeFile(targetPath, content);
      },
      
      // List directory contents
      listDirectory: async (dirPath: string): Promise<string[]> => {
        const targetPath = validatePath(contentBasePath, dirPath);
        
        if (!await fs.pathExists(targetPath)) {
          throw new Error(`Directory not found: ${dirPath}`);
        }
        
        const entries = await fs.readdir(targetPath);
        return entries;
      },
      
      // Check if path exists
      exists: async (filePath: string): Promise<boolean> => {
        const targetPath = validatePath(contentBasePath, filePath);
        return fs.pathExists(targetPath);
      },
      
      // Get file/directory stats
      stat: async (filePath: string): Promise<fs.Stats> => {
        const targetPath = validatePath(contentBasePath, filePath);
        return fs.stat(targetPath);
      },
      
      // Create directory
      mkdir: async (dirPath: string): Promise<void> => {
        const targetPath = validatePath(contentBasePath, dirPath);
        return fs.mkdirp(targetPath);
      },
      
      // Remove file or directory
      remove: async (filePath: string): Promise<void> => {
        const targetPath = validatePath(contentBasePath, filePath);
        return fs.remove(targetPath);
      },
      
      // Copy file or directory
      copy: async (src: string, dest: string): Promise<void> => {
        const srcPath = validatePath(contentBasePath, src);
        const destPath = validatePath(contentBasePath, dest);
        return fs.copy(srcPath, destPath);
      },
      
      // Move file or directory
      move: async (src: string, dest: string): Promise<void> => {
        const srcPath = validatePath(contentBasePath, src);
        const destPath = validatePath(contentBasePath, dest);
        return fs.move(srcPath, destPath);
      },
      
      // Get directory tree
      getTree: async (): Promise<TreeNode> => {
        if (directoryTree) {
          return directoryTree;
        }
        throw new Error('Directory tree not available in workspace package');
      },
      
      // Get file index
      getIndex: async (): Promise<FileIndex> => {
        if (fileIndex) {
          return fileIndex;
        }
        throw new Error('File index not available in workspace package');
      }
    }
  };
  
  return workspace;
}

/**
 * Clean up workspace resources
 * @param workspace - Workspace environment to clean up
 * @returns Promise resolving when cleanup is complete
 */
export async function cleanupWorkspace(workspace: WorkspaceEnvironment): Promise<void> {
  // Get the extraction path from the mount point
  const extractPath = path.dirname(workspace.mountPoint);
  
  // Remove the extraction directory
  if (await fs.pathExists(extractPath)) {
    await fs.remove(extractPath);
  }
}
