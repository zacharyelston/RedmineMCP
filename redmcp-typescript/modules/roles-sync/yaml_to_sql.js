#!/usr/bin/env node
/**
 * yaml_to_sql.js
 * 
 * This script converts YAML configuration files for roles into SQL scripts
 * that can be used to initialize a Redmine instance with the appropriate
 * roles, users, groups, and custom fields.
 * 
 * Usage:
 *   node yaml_to_sql.js --config <config_dir> --output <output_dir>
 * 
 * Arguments:
 *   --config  Directory containing YAML role configuration files
 *   --output  Directory where SQL output files should be written
 *   --force   Overwrite existing SQL files without prompting
 *   --validate Only validate YAML files without generating SQL
 * 
 * Example:
 *   node yaml_to_sql.js --config ./role-configs --output ./sql-output
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { program } = require('commander');

// Import necessary utilities
const { validateRoleConfig } = require('./lib/validators');
const { generateRoleSql } = require('./lib/sql-generators/role-generator');
const { generateUserSql } = require('./lib/sql-generators/user-generator');
const { generateCustomFieldSql } = require('./lib/sql-generators/custom-field-generator');
const { generateMembershipSql } = require('./lib/sql-generators/membership-generator');
const { generateSetupScript } = require('./lib/script-generators/setup-generator');

program
  .description('Converts YAML role configuration files to SQL')
  .option('--config <dir>', 'Directory containing YAML role configurations')
  .option('--output <dir>', 'Directory where SQL files should be written')
  .option('--force', 'Overwrite existing SQL files without prompting', false)
  .option('--validate', 'Only validate YAML files without generating SQL', false)
  .parse(process.argv);

const options = program.opts();

// Validate required arguments
if (!options.config) {
  console.error('Error: --config directory is required');
  process.exit(1);
}

if (!options.validate && !options.output) {
  console.error('Error: --output directory is required when not in validate mode');
  process.exit(1);
}

// Function to process a single YAML config file
async function processRoleConfig(filePath, outputDir, forceOverwrite) {
  try {
    console.log(`Processing ${filePath}...`);
    
    // Read and parse YAML file
    const content = fs.readFileSync(filePath, 'utf8');
    const config = yaml.load(content);
    
    // Validate configuration
    const validationResult = validateRoleConfig(config);
    if (!validationResult.isValid) {
      console.error(`Validation failed for ${filePath}:`);
      validationResult.errors.forEach(err => console.error(`  - ${err}`));
      return false;
    }
    
    // If only validating, don't generate SQL
    if (options.validate) {
      console.log(`✓ ${filePath} is valid`);
      return true;
    }
    
    // Create base filename from the role name
    const roleName = config.role.name.toLowerCase().replace(/\s+/g, '_');
    const baseOutputName = `${roleName}_setup`;
    
    // Generate SQL files
    const roleSql = generateRoleSql(config);
    const userSql = generateUserSql(config);
    const customFieldSql = generateCustomFieldSql(config);
    const membershipSql = generateMembershipSql(config);
    
    // Combine SQL statements into a single file with transactions
    const combinedSql = [
      '-- Combined SQL script for role setup',
      '-- Generated automatically by yaml_to_sql.js',
      `-- Source: ${path.basename(filePath)}`,
      `-- Generated: ${new Date().toISOString()}`,
      '',
      'START TRANSACTION;',
      '',
      '-- Role definition',
      roleSql,
      '',
      '-- User setup for this role',
      userSql,
      '',
      '-- Custom fields for this role',
      customFieldSql,
      '',
      '-- Project memberships',
      membershipSql,
      '',
      'COMMIT;',
      '',
      '-- Verification queries',
      'SELECT id, name FROM roles WHERE name = \'' + config.role.name + '\';',
      'SELECT id, login FROM users WHERE login LIKE \'' + roleName + '_%\';',
      'SELECT name, field_format FROM custom_fields WHERE name IN (\'' + 
        config.role.custom_fields.map(cf => cf.name).join('\', \'') + 
      '\');'
    ].join('\n');
    
    // Write combined SQL to file
    const outputPath = path.join(outputDir, `${baseOutputName}.sql`);
    if (fs.existsSync(outputPath) && !forceOverwrite) {
      console.error(`Output file ${outputPath} already exists. Use --force to overwrite.`);
      return false;
    }
    
    fs.writeFileSync(outputPath, combinedSql, 'utf8');
    console.log(`✓ Generated SQL saved to ${outputPath}`);
    
    // Generate setup script
    const setupScript = generateSetupScript(config, baseOutputName);
    const scriptPath = path.join(outputDir, `${baseOutputName}.sh`);
    
    if (fs.existsSync(scriptPath) && !forceOverwrite) {
      console.error(`Output file ${scriptPath} already exists. Use --force to overwrite.`);
    } else {
      fs.writeFileSync(scriptPath, setupScript, 'utf8');
      fs.chmodSync(scriptPath, '755'); // Make executable
      console.log(`✓ Generated setup script saved to ${scriptPath}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error processing ${filePath}:`, error);
    return false;
  }
}

// Main function to process all YAML files in the config directory
async function main() {
  // Ensure config directory exists
  if (!fs.existsSync(options.config)) {
    console.error(`Config directory ${options.config} does not exist`);
    process.exit(1);
  }
  
  // Ensure output directory exists if we're generating SQL
  if (!options.validate) {
    if (!fs.existsSync(options.output)) {
      console.log(`Creating output directory ${options.output}`);
      fs.mkdirSync(options.output, { recursive: true });
    }
  }
  
  // Get list of YAML files in config directory
  const files = fs.readdirSync(options.config)
    .filter(file => file.endsWith('.yaml') || file.endsWith('.yml'))
    .map(file => path.join(options.config, file));
  
  if (files.length === 0) {
    console.error(`No YAML files found in ${options.config}`);
    process.exit(1);
  }
  
  console.log(`Found ${files.length} YAML configuration files`);
  
  // Process each file
  let successCount = 0;
  let failureCount = 0;
  
  for (const file of files) {
    const success = await processRoleConfig(file, options.output, options.force);
    if (success) {
      successCount++;
    } else {
      failureCount++;
    }
  }
  
  // Print summary
  console.log('\nSummary:');
  console.log(`  Total files processed: ${files.length}`);
  console.log(`  Successful: ${successCount}`);
  console.log(`  Failed: ${failureCount}`);
  
  if (failureCount > 0) {
    process.exit(1);
  }
}

// Run the main function
main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
