
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const rootDir = '/redmine-mcp';
const outputFile = path.join(rootDir, 'filesystem-read-tests', 'filesystem-metadata.json');
const excludePatterns = [
  'node_modules',
  '.git',
  'build',
  'dist'
];

// Function to check if path should be excluded
function isExcluded(filePath) {
  return excludePatterns.some(pattern => filePath.includes(pattern));
}

// Function to get file stats
function getFileStats(filePath) {
  try {
    const stats = fs.statSync(filePath);
    return {
      path: filePath,
      size: stats.size,
      created: stats.birthtime,
      modified: stats.mtime,
      accessed: stats.atime,
      isDirectory: stats.isDirectory(),
      mode: stats.mode.toString(8).slice(-3), // Convert to octal permission string
      type: getFileType(filePath, stats)
    };
  } catch (error) {
    console.error(`Error getting stats for ${filePath}:`, error.message);
    return null;
  }
}

// Helper to determine file type
function getFileType(filePath, stats) {
  if (stats.isDirectory()) return 'directory';
  
  const ext = path.extname(filePath).toLowerCase();
  if (['.ts', '.js', '.jsx', '.tsx'].includes(ext)) return 'script';
  if (['.json', '.yaml', '.yml'].includes(ext)) return 'config';
  if (['.md', '.txt'].includes(ext)) return 'document';
  if (['.png', '.jpg', '.jpeg', '.gif', '.svg'].includes(ext)) return 'image';
  return 'other';
}

// Function to recursively traverse directory
function traverseDirectory(dirPath, result = []) {
  if (isExcluded(dirPath)) return result;

  // Get directory stats
  const dirStats = getFileStats(dirPath);
  if (dirStats) result.push(dirStats);

  try {
    const entries = fs.readdirSync(dirPath);
    
    // Process each entry
    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry);
      
      // Skip excluded paths
      if (isExcluded(fullPath)) continue;
      
      try {
        const stats = fs.statSync(fullPath);
        
        if (stats.isDirectory()) {
          // Recursively process directory
          traverseDirectory(fullPath, result);
        } else {
          // Get file stats
          const fileStats = getFileStats(fullPath);
          if (fileStats) result.push(fileStats);
        }
      } catch (error) {
        console.error(`Error processing ${fullPath}:`, error.message);
      }
    }
  } catch (error) {
    console.error(`Error reading directory ${dirPath}:`, error.message);
  }
  
  return result;
}

// Main function to generate filesystem metadata
function generateFilesystemMetadata() {
  console.log(`Generating filesystem metadata for ${rootDir}...`);
  const startTime = Date.now();
  
  // Traverse directory and collect metadata
  const metadata = traverseDirectory(rootDir);
  
  // Write output to JSON file
  fs.writeFileSync(outputFile, JSON.stringify(metadata, null, 2));
  
  const endTime = Date.now();
  console.log(`Metadata generation complete. Processed ${metadata.length} files in ${(endTime - startTime) / 1000} seconds.`);
  console.log(`Output written to: ${outputFile}`);
}

// Run the script
generateFilesystemMetadata();
