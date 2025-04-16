/**
 * file-indexer.ts
 * Indexes the content of files with metadata
 */

import fs from 'fs-extra';
import path from 'path';
import { glob } from 'glob';
import crypto from 'crypto';

export interface FileMetadata {
  path: string;
  relativePath: string;
  size: number;
  modified: Date;
  created: Date;
  extension: string;
  mimeType?: string;
  hash: string;
  type: string;
}

export interface FileIndex {
  rootDir: string;
  totalSize: number;
  fileCount: number;
  indexedAt: Date;
  files: Record<string, FileMetadata>;
}

export interface FileIndexerOptions {
  rootDir: string;
  outputFile?: string;
  excludePatterns?: string[];
  calculateHashes?: boolean;
  detectMimeTypes?: boolean;
}

/**
 * Detect MIME type based on file extension
 * @param filePath - Path to the file
 * @returns MIME type string or undefined
 */
function detectMimeType(filePath: string): string | undefined {
  const ext = path.extname(filePath).toLowerCase();
  
  // Basic mapping of common extensions to MIME types
  const mimeMap: Record<string, string> = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.ts': 'application/typescript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.pdf': 'application/pdf',
    '.md': 'text/markdown',
    '.txt': 'text/plain',
    '.xml': 'application/xml',
    '.zip': 'application/zip',
    '.gz': 'application/gzip',
    '.tar': 'application/x-tar',
    '.mp3': 'audio/mpeg',
    '.mp4': 'video/mp4',
    '.wav': 'audio/wav',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.ppt': 'application/vnd.ms-powerpoint',
    '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };
  
  return mimeMap[ext];
}

/**
 * Calculate hash for a file
 * @param filePath - Path to the file
 * @returns SHA-256 hash
 */
async function calculateFileHash(filePath: string): Promise<string> {
  const hash = crypto.createHash('sha256');
  const stream = fs.createReadStream(filePath);
  
  return new Promise<string>((resolve, reject) => {
    stream.on('data', data => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', error => reject(error));
  });
}

/**
 * Determine file type based on extension
 * @param filePath - Path to the file
 * @returns File type string
 */
function determineFileType(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  
  // Map extensions to file types
  if (['.js', '.ts', '.jsx', '.tsx'].includes(ext)) return 'script';
  if (['.json', '.yaml', '.yml', '.toml', '.ini', '.env'].includes(ext)) return 'config';
  if (['.md', '.txt', '.rtf', '.doc', '.docx'].includes(ext)) return 'document';
  if (['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.svg', '.webp'].includes(ext)) return 'image';
  if (['.mp3', '.wav', '.ogg', '.flac', '.aac'].includes(ext)) return 'audio';
  if (['.mp4', '.webm', '.avi', '.mov', '.mkv'].includes(ext)) return 'video';
  if (['.zip', '.rar', '.tar', '.gz', '.7z'].includes(ext)) return 'archive';
  
  return 'other';
}

/**
 * Index files in a directory
 * @param options - File indexer options
 * @returns Promise resolving to file index
 */
export async function indexFiles(options: FileIndexerOptions): Promise<FileIndex> {
  const { 
    rootDir, 
    excludePatterns = [], 
    calculateHashes = true,
    detectMimeTypes = true 
  } = options;
  
  if (!await fs.pathExists(rootDir)) {
    throw new Error(`Directory not found: ${rootDir}`);
  }
  
  const index: FileIndex = {
    rootDir,
    totalSize: 0,
    fileCount: 0,
    indexedAt: new Date(),
    files: {}
  };
  
  try {
    // Get all files (not directories) recursively
    const files = await glob('**/*', {
      cwd: rootDir,
      dot: true,
      ignore: excludePatterns,
      nodir: true,
      posix: true,
    });
    
    // Process each file
    for (const relativePath of files) {
      const filePath = path.join(rootDir, relativePath);
      const stats = await fs.stat(filePath);
      
      const metadata: FileMetadata = {
        path: filePath,
        relativePath,
        size: stats.size,
        modified: stats.mtime,
        created: stats.birthtime,
        extension: path.extname(filePath).toLowerCase(),
        hash: calculateHashes ? await calculateFileHash(filePath) : '',
        type: determineFileType(filePath)
      };
      
      if (detectMimeTypes) {
        metadata.mimeType = detectMimeType(filePath);
      }
      
      index.files[relativePath] = metadata;
      index.totalSize += stats.size;
      index.fileCount += 1;
    }
    
    // If outputFile provided, write index to file
    if (options.outputFile) {
      await fs.writeJson(options.outputFile, index, { spaces: 2 });
    }
    
    return index;
  } catch (error) {
    throw new Error(`Failed to index files: ${(error as Error).message}`);
  }
}
