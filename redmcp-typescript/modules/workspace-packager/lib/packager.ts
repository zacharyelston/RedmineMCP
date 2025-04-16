/**
 * packager.ts
 * Creates a tar archive with attached metadata
 */

import fs from 'fs-extra';
import path from 'path';
import tar from 'tar';
import { v4 as uuidv4 } from 'uuid';
import os from 'os';
import { FileIndex } from './file-indexer';
import { TreeNode } from './tree-generator';

export interface WorkspaceMetadata {
  workspaceId: string;
  createdAt: Date;
  sourceDirectory: string;
  fileCount: number;
  totalSize: number;
  customMetadata?: Record<string, any>;
}

export interface PackagerOptions {
  sourceDir: string;
  outputDir?: string;
  excludePatterns?: string[];
  fileIndex?: FileIndex;
  directoryTree?: TreeNode;
  customMetadata?: Record<string, any>;
}

export interface PackageResult {
  packagePath: string;
  metadata: WorkspaceMetadata;
}

/**
 * Create a workspace package
 * @param options - Packager options
 * @returns Promise resolving to package result
 */
export async function createPackage(options: PackagerOptions): Promise<PackageResult> {
  const { 
    sourceDir, 
    excludePatterns = [],
    customMetadata = {},
    fileIndex,
    directoryTree
  } = options;
  
  // Use provided output directory or create temp directory
  const outputDir = options.outputDir || await fs.mkdtemp(path.join(os.tmpdir(), 'workspace-'));
  
  if (!await fs.pathExists(sourceDir)) {
    throw new Error(`Source directory not found: ${sourceDir}`);
  }
  
  if (!await fs.pathExists(outputDir)) {
    await fs.mkdirp(outputDir);
  }
  
  // Create workspace ID
  const workspaceId = uuidv4();
  
  // Create temporary directory for packaging
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), `workspace-${workspaceId}-`));
  const tempContentDir = path.join(tempDir, 'content');
  
  try {
    // Create content directory
    await fs.mkdirp(tempContentDir);
    
    // Copy all files from source directory to temp directory
    await fs.copy(sourceDir, tempContentDir, {
      filter: (src) => {
        const relativePath = path.relative(sourceDir, src);
        return !excludePatterns.some(pattern => 
          new RegExp(pattern).test(relativePath)
        );
      }
    });
    
    // Generate metadata
    const metadata: WorkspaceMetadata = {
      workspaceId,
      createdAt: new Date(),
      sourceDirectory: sourceDir,
      fileCount: fileIndex?.fileCount || 0,
      totalSize: fileIndex?.totalSize || 0,
      customMetadata
    };
    
    // Write metadata to temp directory
    await fs.writeJson(path.join(tempDir, 'workspace-metadata.json'), metadata, { spaces: 2 });
    
    // Write file index if provided
    if (fileIndex) {
      await fs.writeJson(path.join(tempDir, 'workspace-index.json'), fileIndex, { spaces: 2 });
    }
    
    // Write directory tree if provided
    if (directoryTree) {
      await fs.writeJson(path.join(tempDir, 'workspace-tree.json'), directoryTree, { spaces: 2 });
    }
    
    // Create tar archive
    const packageName = `workspace-${workspaceId}.tar.gz`;
    const packagePath = path.join(outputDir, packageName);
    
    await tar.create(
      {
        gzip: true,
        file: packagePath,
        cwd: tempDir
      },
      ['workspace-metadata.json', 'workspace-index.json', 'workspace-tree.json', 'content']
    );
    
    // Clean up temp directory
    await fs.remove(tempDir);
    
    return {
      packagePath,
      metadata
    };
  } catch (error) {
    // Clean up temp directory on error
    await fs.remove(tempDir);
    throw new Error(`Failed to create package: ${(error as Error).message}`);
  }
}

/**
 * Extract and read workspace metadata from package
 * @param packagePath - Path to workspace package
 * @returns Promise resolving to workspace metadata
 */
export async function readPackageMetadata(packagePath: string): Promise<WorkspaceMetadata> {
  if (!await fs.pathExists(packagePath)) {
    throw new Error(`Package not found: ${packagePath}`);
  }
  
  // Create temporary directory for extraction
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'workspace-meta-'));
  
  try {
    // Extract only the metadata file
    await tar.extract({
      file: packagePath,
      cwd: tempDir,
      filter: (path) => path === 'workspace-metadata.json'
    });
    
    // Read metadata
    const metadataPath = path.join(tempDir, 'workspace-metadata.json');
    
    if (!await fs.pathExists(metadataPath)) {
      throw new Error('Metadata file not found in package');
    }
    
    const metadata = await fs.readJson(metadataPath) as WorkspaceMetadata;
    
    // Clean up temp directory
    await fs.remove(tempDir);
    
    return metadata;
  } catch (error) {
    // Clean up temp directory on error
    await fs.remove(tempDir);
    throw new Error(`Failed to read package metadata: ${(error as Error).message}`);
  }
}

/**
 * Extract workspace package to a directory
 * @param packagePath - Path to workspace package
 * @param outputDir - Output directory
 * @returns Promise resolving to extraction path and metadata
 */
export async function extractPackage(
  packagePath: string, 
  outputDir?: string
): Promise<{ extractPath: string; metadata: WorkspaceMetadata }> {
  if (!await fs.pathExists(packagePath)) {
    throw new Error(`Package not found: ${packagePath}`);
  }
  
  // Use provided output directory or create temp directory
  const extractDir = outputDir || await fs.mkdtemp(path.join(os.tmpdir(), 'workspace-'));
  
  if (!await fs.pathExists(extractDir)) {
    await fs.mkdirp(extractDir);
  }
  
  try {
    // Extract package
    await tar.extract({
      file: packagePath,
      cwd: extractDir
    });
    
    // Read metadata
    const metadataPath = path.join(extractDir, 'workspace-metadata.json');
    
    if (!await fs.pathExists(metadataPath)) {
      throw new Error('Metadata file not found in package');
    }
    
    const metadata = await fs.readJson(metadataPath) as WorkspaceMetadata;
    
    return {
      extractPath: extractDir,
      metadata
    };
  } catch (error) {
    throw new Error(`Failed to extract package: ${(error as Error).message}`);
  }
}
