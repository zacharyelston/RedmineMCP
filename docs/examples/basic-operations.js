/**
 * Basic Redmine MCP Operations Example
 * 
 * This script demonstrates the basic operations available in the Redmine MCP integration.
 * It includes examples of listing projects, getting project details, listing issues,
 * creating and updating issues, and retrieving user information.
 */

// Example 1: List all projects
async function listAllProjects() {
  try {
    const result = await redmine_projects_list({limit: 100});
    console.log("Available projects:", result.projects.map(p => `${p.id}: ${p.name}`).join('\n'));
    return result;
  } catch (error) {
    console.error("Error listing projects:", error);
  }
}

// Example 2: Get project details
async function getProjectDetails(identifier) {
  try {
    const result = await redmine_projects_get({
      identifier, 
      include: ['trackers', 'issue_categories']
    });
    console.log(`Project details for ${result.project.name}:`);
    console.log(`- Description: ${result.project.description}`);
    console.log(`- Trackers: ${result.project.trackers.map(t => t.name).join(', ')}`);
    return result;
  } catch (error) {
    console.error(`Error getting project details for ${identifier}:`, error);
  }
}

// Example 3: List issues for a project
async function listProjectIssues(projectId) {
  try {
    const result = await redmine_issues_list({
      project_id: projectId, 
      limit: 25
    });
    console.log(`Issues for project ${projectId}:`);
    result.issues.forEach(issue => {
      console.log(`- #${issue.id}: ${issue.subject} (${issue.status.name})`);
    });
    return result;
  } catch (error) {
    console.error(`Error listing issues for project ${projectId}:`, error);
  }
}

// Example 4: Create a new issue
async function createNewIssue(projectId, subject, description) {
  try {
    const result = await redmine_issues_create({
      project_id: projectId,
      subject,
      description,
      tracker_id: 2, // Feature
      priority_id: 2, // Normal
    });
    console.log(`Created new issue #${result.issue.id}: ${subject}`);
    return result;
  } catch (error) {
    console.error(`Error creating new issue:`, error);
  }
}

// Example 5: Update an existing issue
async function updateIssue(issueId, updates) {
  try {
    const result = await redmine_issues_update({
      issue_id: issueId,
      ...updates
    });
    console.log(`Updated issue #${issueId}`);
    return result;
  } catch (error) {
    console.error(`Error updating issue #${issueId}:`, error);
  }
}

// Example 6: Get current user information
async function getCurrentUser() {
  try {
    const result = await redmine_users_current({});
    console.log(`Current user: ${result.user.firstname} ${result.user.lastname} (${result.user.login})`);
    return result;
  } catch (error) {
    console.error("Error getting current user:", error);
  }
}

// Example 7: Search for issues with a specific term
async function searchIssues(term) {
  try {
    const result = await redmine_issues_list({
      subject: `~${term}`
    });
    console.log(`Found ${result.total_count} issues matching "${term}"`);
    result.issues.forEach(issue => {
      console.log(`- #${issue.id}: ${issue.subject} (${issue.project.name})`);
    });
    return result;
  } catch (error) {
    console.error(`Error searching for issues with term "${term}":`, error);
  }
}

// Example usage:
async function runExamples() {
  // Get the current user information
  await getCurrentUser();
  
  // List all available projects
  const projects = await listAllProjects();
  
  // Get details for the MCP Project
  await getProjectDetails('mcp-project');
  
  // List issues for the MCP Project
  await listProjectIssues(1);
  
  // Create a new test issue
  const newIssue = await createNewIssue(
    1, 
    'Test issue from MCP example', 
    'This is a test issue created by the basic operations example script'
  );
  
  // Update the issue we just created
  if (newIssue && newIssue.issue) {
    await updateIssue(newIssue.issue.id, {
      status_id: 2, // In Progress
      priority_id: 3, // High
      estimated_hours: 4
    });
  }
  
  // Search for documentation issues
  await searchIssues('Documentation');
}

// Run the examples
runExamples().catch(console.error);
