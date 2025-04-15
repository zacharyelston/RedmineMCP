/**
 * Common Redmine MCP Workflows Example
 * 
 * This script demonstrates common workflows when working with the Redmine MCP integration.
 * It includes examples of adding time tracking, changing issue status, reassigning issues,
 * and moving issues between projects.
 */

// Helper function to get issue details
async function getIssueDetails(issueId) {
  try {
    const result = await redmine_issues_get({
      issue_id: issueId,
      include: ['journals', 'watchers', 'relations']
    });
    return result.issue;
  } catch (error) {
    console.error(`Error getting issue #${issueId}:`, error);
    return null;
  }
}

// Workflow 1: Add time tracking to an issue
async function addTimeTracking(issueId, estimatedHours) {
  try {
    // First, get the current issue details to verify it exists
    const issue = await getIssueDetails(issueId);
    if (!issue) {
      console.error(`Issue #${issueId} not found`);
      return;
    }
    
    console.log(`Adding time tracking to issue #${issueId}: ${issue.subject}`);
    console.log(`Current estimated hours: ${issue.estimated_hours || 'None'}`);
    
    // Update the issue with the estimated hours
    const result = await redmine_issues_update({
      issue_id: issueId,
      estimated_hours: estimatedHours
    });
    
    console.log(`Updated issue #${issueId} with ${estimatedHours} estimated hours`);
    return result;
  } catch (error) {
    console.error(`Error adding time tracking to issue #${issueId}:`, error);
  }
}

// Workflow 2: Change the status of an issue
async function changeIssueStatus(issueId, statusId) {
  try {
    // First, get the current issue details to see its current status
    const issue = await getIssueDetails(issueId);
    if (!issue) {
      console.error(`Issue #${issueId} not found`);
      return;
    }
    
    console.log(`Changing status of issue #${issueId}: ${issue.subject}`);
    console.log(`Current status: ${issue.status.name} (ID: ${issue.status.id})`);
    
    // Update the issue with the new status
    const result = await redmine_issues_update({
      issue_id: issueId,
      status_id: statusId
    });
    
    console.log(`Updated issue #${issueId} status to ID ${statusId}`);
    return result;
  } catch (error) {
    console.error(`Error changing status of issue #${issueId}:`, error);
  }
}

// Workflow 3: Reassign an issue to a different user
async function reassignIssue(issueId, assigneeId) {
  try {
    // First, get the current issue details to see its current assignee
    const issue = await getIssueDetails(issueId);
    if (!issue) {
      console.error(`Issue #${issueId} not found`);
      return;
    }
    
    console.log(`Reassigning issue #${issueId}: ${issue.subject}`);
    console.log(`Current assignee: ${issue.assigned_to ? issue.assigned_to.name : 'None'}`);
    
    // Update the issue with the new assignee
    const result = await redmine_issues_update({
      issue_id: issueId,
      assigned_to_id: assigneeId
    });
    
    console.log(`Reassigned issue #${issueId} to user ID ${assigneeId}`);
    return result;
  } catch (error) {
    console.error(`Error reassigning issue #${issueId}:`, error);
  }
}

// Workflow 4: Move an issue to a different project
async function moveIssueToProject(issueId, projectId) {
  try {
    // First, get the current issue details to see its current project
    const issue = await getIssueDetails(issueId);
    if (!issue) {
      console.error(`Issue #${issueId} not found`);
      return;
    }
    
    console.log(`Moving issue #${issueId}: ${issue.subject}`);
    console.log(`Current project: ${issue.project.name} (ID: ${issue.project.id})`);
    
    // For project transfers, we need to include all the relevant fields
    // to maintain issue integrity
    const updatePayload = {
      issue_id: issueId,
      project_id: projectId,
      subject: issue.subject,
      description: issue.description,
      tracker_id: issue.tracker.id,
      priority_id: issue.priority.id,
      status_id: issue.status.id
    };
    
    // If the issue has an assignee, include that too
    if (issue.assigned_to) {
      updatePayload.assigned_to_id = issue.assigned_to.id;
    }
    
    // Update the issue with the new project
    const result = await redmine_issues_update(updatePayload);
    
    console.log(`Moved issue #${issueId} to project ID ${projectId}`);
    
    // Verify the issue was moved successfully by getting it again
    const updatedIssue = await getIssueDetails(issueId);
    if (updatedIssue && updatedIssue.project.id === projectId) {
      console.log(`Verified: Issue #${issueId} is now in project ${updatedIssue.project.name}`);
    } else {
      console.warn(`Warning: Issue #${issueId} may not have been moved properly. Verify manually.`);
    }
    
    return result;
  } catch (error) {
    console.error(`Error moving issue #${issueId} to project ID ${projectId}:`, error);
  }
}

// Example usage:
async function runWorkflowExamples() {
  // For demo purposes, let's create a test issue
  console.log("Creating a test issue...");
  const newIssue = await redmine_issues_create({
    project_id: 1, // MCP Project
    subject: 'Workflow test issue',
    description: 'This is a test issue for demonstrating common workflows',
    tracker_id: 3, // Support
    priority_id: 2, // Normal
  });
  
  if (!newIssue || !newIssue.issue) {
    console.error("Failed to create test issue. Exiting.");
    return;
  }
  
  const issueId = newIssue.issue.id;
  console.log(`Created test issue #${issueId}`);
  
  // Wait a moment between operations
  const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
  
  // Run the workflows
  await wait(1000);
  await addTimeTracking(issueId, 8);
  
  await wait(1000);
  await changeIssueStatus(issueId, 2); // In Progress
  
  await wait(1000);
  await reassignIssue(issueId, 3); // Assign to developer
  
  await wait(1000);
  // Move to the docs subproject
  await moveIssueToProject(issueId, 6);
  
  console.log("Workflow examples completed successfully!");
}

// Run the workflow examples
runWorkflowExamples().catch(console.error);
