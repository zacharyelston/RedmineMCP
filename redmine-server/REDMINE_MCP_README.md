# Redmine MCP Integration - Troubleshooting & TODOs

This document outlines known issues, troubleshooting steps, and recommended fixes for the Redmine MCP (ModelContextProtocol) integration.

## Current Status

The Redmine MCP integration has the following functionality status:

**Working Functions:**
- `redmine_projects_list` - Successfully retrieves the list of projects
- `redmine_projects_get` - Successfully retrieves detailed information about projects
- `redmine_issues_list` - Successfully executes but may return an empty list if no issues exist
- `redmine_users_current` - Successfully retrieves current user information

**Non-Working Functions:**
- `redmine_issues_create` - Fails with a 422 error code (Unprocessable Entity)
- `redmine_issues_get` - Fails with a 404 error code (Not Found) if no issues exist
- `redmine_issues_update` - Not fully tested due to inability to create issues

## Identified Issues

### 1. Missing Priorities

**Issue:** The Redmine database was missing issue priorities in the `enumerations` table.

**Fix:** Created standard priorities (Low, Normal, High, Urgent, Immediate) using the `create_priorities.sql` script.

### 2. Missing Default Status ID

**Issue:** Trackers created via SQL were missing the required `default_status_id` field.

**Fix:** Updated trackers to use the "New" status (ID: 1) as their default status using the `fix_all_trackers_v2.sql` script.

### 3. Issue Creation API Problem

**Issue:** The `redmine_issues_create` function fails with a 422 error while direct API calls work.

**Root Cause:** After examining the code in `api_client.rb` and `issue_handlers.rb`, the issue appears to be in how the request payload is structured when sent to the Redmine API. The API expects parameters nested under an "issue" object.

## TODO List

### High Priority

1. **Fix Issue Creation Functionality**
   - [ ] Modify `api_client.rb` to properly structure the issue creation request
   - [ ] Test the fix with various parameter combinations
   - [ ] Ensure error handling provides useful feedback

### Medium Priority

2. **Improve Error Handling**
   - [ ] Add more detailed error logging throughout the MCP integration
   - [ ] Ensure error messages from the Redmine API are properly captured and displayed
   - [ ] Add validation for required fields at the handler level

3. **Add Configuration Validation**
   - [ ] Validate configuration on startup
   - [ ] Check API key validity on initialization
   - [ ] Verify database setup (priorities, statuses, etc.)

### Low Priority

4. **Develop Testing Suite**
   - [ ] Create automated tests for all MCP functions
   - [ ] Add integration tests with the Redmine API
   - [ ] Implement CI/CD pipeline for testing

5. **Documentation Improvements**
   - [ ] Document all available functions and parameters
   - [ ] Add troubleshooting guides for common issues
   - [ ] Update example code for all functions

## Fix Proposal for Issue Creation

The proposed fix for the issue creation functionality involves modifying the `create_issue` method in `api_client.rb`:

```ruby
def create_issue(project_id, subject, description = nil, tracker_id = nil, status_id = nil, priority_id = nil, assigned_to_id = nil)
  @logger.info("Creating issue: #{subject} for project #{project_id}")
  
  # Create properly nested issue data structure
  data = {
    issue: {
      project_id: project_id,
      subject: subject
    }
  }
  
  # Add optional parameters if specified
  data[:issue][:description] = description if description
  data[:issue][:tracker_id] = tracker_id if tracker_id
  data[:issue][:status_id] = status_id if status_id
  data[:issue][:priority_id] = priority_id if priority_id
  data[:issue][:assigned_to_id] = assigned_to_id if assigned_to_id
  
  # Make the request with the properly structured data
  response = make_request(:post, "issues.json", data)
  response["issue"]
end
```

Additionally, improve error handling in the `make_request` method:

```ruby
rescue RestClient::Exception => e
  @logger.error("API request failed: #{e.message}")
  if e.response
    @logger.error("Response code: #{e.response.code}")
    @logger.error("Response body: #{e.response.body}")
    
    # Try to parse and log the error details
    begin
      error_details = JSON.parse(e.response.body)
      @logger.error("Error details: #{error_details}")
    rescue JSON::ParserError
      @logger.error("Could not parse error response")
    end
  end
  raise "Redmine API request failed: #{e.message}"
```

## SQL Scripts

The following SQL scripts were created to address various issues:

1. **01_create_tracker.sql** - Creates new trackers with proper default status
2. **02_associate_with_project.sql** - Associates trackers with the MCP project
3. **03_create_workflow_developer.sql** - Sets up workflow transitions for Developer role
4. **04_create_workflow_manager.sql** - Sets up workflow transitions for Manager role
5. **05_create_workflow_reporter.sql** - Sets up workflow transitions for Reporter role
6. **06_verify_trackers.sql** - Verifies tracker configuration
7. **create_priorities.sql** - Creates standard issue priorities
8. **fix_trackers.sql** - Fixes trackers missing default_status_id
9. **fix_all_trackers_v2.sql** - Fixes all trackers with missing default_status_id

## Testing & Verification

After making code changes:

1. Restart the Redmine MCP server
2. Test the issue creation with:

```javascript
redmine_issues_create({
  "project_id": 1,
  "subject": "Test Issue After Fix",
  "tracker_id": 1,
  "priority_id": 2,
  "status_id": 1
});
```

3. Verify the created issue using:

```javascript
redmine_issues_list({
  "project_id": "mcp-project"
});
```

## Temporary Workaround

Until the MCP integration is fixed, issues can be created directly via the Redmine API using the `direct_create_issue.sh` script:

```bash
./direct_create_issue.sh 1 "Test Issue" 1 2
```

Parameters:
1. Project ID (default: 1)
2. Subject (default: "Test Issue from direct script")
3. Tracker ID (default: 1 for Bug)
4. Priority ID (default: 2 for Normal)

---

Document last updated: April 14, 2025
