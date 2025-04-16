/**
 * tree-generator.ts
 * Creates a recursive tree representation of a directory structure
 */

import fs from 'fs-extra';
import path from 'path';
import { glob } from 'glob';

export interface TreeNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  size?: number;
  modified?: Date;
  children?: TreeNode[];
}

export interface TreeGeneratorOptions {
  rootDir: string;
  outputFile?: string;
  excludePatterns?: string[];
}

/**
 * Generate a tree representation of a directory
 * @param options - Tree generator options
 * @returns Promise resolving to tree structure
 */
export async function generateTree(options: TreeGeneratorOptions): Promise<TreeNode> {
  const { rootDir, excludePatterns = [] } = options;
  
  if (!await fs.pathExists(rootDir)) {
    throw new Error(`Directory not found: ${rootDir}`);
  }
  
  // Create the root node
  const rootNode: TreeNode = {
    name: path.basename(rootDir),
    path: rootDir,
    type: 'directory',
    children: []
  };
  
  try {
    // Get all files and directories, including in subdirectories
    const entries = await glob('**/*', { 
      cwd: rootDir,
      dot: true,
      mark: true, // Adds / to directories
      ignore: excludePatterns,
      posix: true, // Use forward slashes
      withFileTypes: true, // For distinguishing directories
    });
    
    // Map of path to node for easy lookup
    const nodeMap = new Map<string, TreeNode>();
    nodeMap.set(rootDir, rootNode);
    
    // Process each entry
    for (const entry of entries) {
      const entryPath = path.join(rootDir, entry.relative);
      const parentPath = path.dirname(entryPath);
      const stats = await fs.stat(entryPath);
      
      // Create node for this entry
      const node: TreeNode = {
        name: path.basename(entryPath),
        path: entryPath,
        type: entry.dirent.isDirectory() ? 'directory' : 'file',
        modified: stats.mtime,
      };
      
      // Add size for files
      if (node.type === 'file') {
        node.size = stats.size;
      } else {
        node.children = [];
      }
      
      // Get parent node
      const parentNode = nodeMap.get(parentPath);
      if (parentNode && parentNode.children) {
        parentNode.children.push(node);
        nodeMap.set(entryPath, node);
      }
    }
    
    // If outputFile provided, write tree to file
    if (options.outputFile) {
      await fs.writeJson(options.outputFile, rootNode, { spaces: 2 });
    }
    
    return rootNode;
  } catch (error) {
    throw new Error(`Failed to generate tree: ${(error as Error).message}`);
  }
}

/**
 * Format tree for console display
 * @param tree - Tree structure to format
 * @param level - Current indentation level
 * @returns Formatted string representation of tree
 */
export function formatTree(tree: TreeNode, level = 0): string {
  const indent = '  '.repeat(level);
  const prefix = tree.type === 'directory' ? '📁 ' : '📄 ';
  
  let result = `${indent}${prefix}${tree.name}\n`;
  
  if (tree.children) {
    tree.children.forEach(child => {
      result += formatTree(child, level + 1);
    });
  }
  
  return result;
}
