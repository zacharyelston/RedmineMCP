# Redmine MCP Troubleshooting

This document provides guidance on troubleshooting and resolving issues with the Redmine MCP integration.

## Issue Creation Function Status

While testing the Redmine MCP integration, we identified a discrepancy between direct API calls and calls made through the MCP server:

- **Direct API Calls**: Successfully create issues in Redmine
- **TypeScript API Client**: Successfully creates issues when called directly
- **MCP Function**: Returns a 422 error (Unprocessable Entity) when called through Claude

## Diagnostic Results

We performed multiple tests to diagnose the issue:

1. **Database Configuration**: 
   - Added missing priorities in the `enumerations` table
   - Fixed trackers with missing `default_status_id` field
   - Verified API key configuration in the `tokens` table

2. **API Client Testing**: 
   - Created a test script that successfully creates issues
   - Verified all required fields are present and formatted correctly

3. **Direct API Testing**:
   - Created issues via curl commands with the same parameters
   - Successfully retrieved and listed issues

## Root Cause Analysis

The issue appears to be in how parameters are passed from Claude to the MCP server and then to the Redmine API. The TypeScript implementation works correctly when called directly, but fails when called through the MCP protocol.

Possible causes:

1. **Parameter Format**: The MCP server might not be correctly formatting the parameters as required by the Redmine API.
2. **Error Handling**: The error information from Redmine is not being properly relayed back to Claude.
3. **MCP Protocol**: There might be an issue with how the MCP protocol handles certain parameter types.

## Recommended Fixes

1. **Enhanced Debugging**:
   - Add detailed logging of request payloads in the MCP server
   - Log the actual request being sent to Redmine
   - Capture and log detailed error responses

2. **Update the RedmineClient.ts File**:
   ```typescript
   // In the createIssue method of RedmineClient.ts
   async createIssue(
     projectId: number,
     subject: string,
     description?: string,
     trackerId?: number,
     statusId?: number,
     priorityId?: number,
     assignedToId?: number
   ) {
     console.error(`Creating issue: "${subject}" for project ${projectId}`);
     
     // Create properly structured data object
     const data: Record<string, any> = {
       issue: {
         project_id: projectId,
         subject: subject
       }
     };
     
     // Add optional parameters if specified
     if (description) data.issue.description = description;
     if (trackerId) data.issue.tracker_id = trackerId;
     if (statusId) data.issue.status_id = statusId;
     if (priorityId) data.issue.priority_id = priorityId;
     if (assignedToId) data.issue.assigned_to_id = assignedToId;
     
     // Log the exact payload being sent (for debugging)
     console.error(`Request payload: ${JSON.stringify(data)}`);
     
     try {
       const response = await this.api.post('/issues.json', data);
       return response.data.issue;
     } catch (error) {
       console.error('Error creating issue:', error);
       
       // Enhanced error reporting
       if (axios.isAxiosError(error) && error.response) {
         console.error(`Status: ${error.response.status}`);
         console.error(`Response: ${JSON.stringify(error.response.data)}`);
       }
       
       throw new Error(`Failed to create Redmine issue: ${(error as Error).message}`);
     }
   }
   ```

3. **Update the MCP Server Tool Definition**:
   ```typescript
   // In index.ts, update the issue creation tool
   server.tool(
     "redmine_issues_create",
     {
       project_id: z.number().describe('Project ID'),
       subject: z.string().describe('Issue subject'),
       description: z.string().optional().describe('Issue description'),
       tracker_id: z.number().optional().describe('Tracker ID'),
       status_id: z.number().optional().describe('Status ID'),
       priority_id: z.number().optional().describe('Priority ID'),
       assigned_to_id: z.number().optional().describe('Assignee ID')
     },
     async ({ project_id, subject, description, tracker_id, status_id, priority_id, assigned_to_id }) => {
       log.debug(`Executing redmine_issues_create (project_id=${project_id}, subject=${subject})`);
       
       // Log all parameters for debugging
       log.debug('Issue creation parameters:', { 
         project_id, subject, description, 
         tracker_id, status_id, priority_id, assigned_to_id 
       });
       
       try {
         const issue = await dataProvider.createIssue(
           project_id,
           subject,
           description,
           tracker_id,
           status_id,
           priority_id,
           assigned_to_id
         );
         
         return {
           content: [{ 
             type: "text", 
             text: JSON.stringify({ issue }, null, 2)
           }]
         };
       } catch (error) {
         // Enhanced error handling
         log.error('Error creating issue:', error);
         
         const errorMessage = `Failed to create issue: ${(error as Error).message}`;
         return {
           content: [{ 
             type: "text", 
             text: JSON.stringify({ 
               error: errorMessage,
               details: (error as any).response?.data || {}
             }, null, 2)
           }]
         };
       }
     }
   );
   ```

4. **Testing with Simpler Parameters**:
   - Try creating an issue with only the minimum required fields:
   ```typescript
   redmine_issues_create({
     project_id: 1,
     subject: "Test Issue"
   })
   ```

## Diagnostic Scripts

We've created several diagnostic scripts to help with troubleshooting:

1. **test-issue-creation.ts**: Tests direct issue creation with the API client
2. **direct-api-call.sh**: Tests issue creation with curl commands
3. **database-diagnosis.sql**: Checks database configuration for issues

## Additional Resources

- [Redmine REST API Documentation](https://www.redmine.org/projects/redmine/wiki/Rest_api)
- [MCP Protocol Documentation](https://help.claude.ai/hc/en-us/articles/27792650253844-Build-tools-with-Claude-using-the-Model-Context-Protocol)
- [Axios Documentation](https://axios-http.com/docs/intro)

## Resolution Status ✅

The issue with creating Redmine issues through the MCP server has been **RESOLVED**. The primary problem was the lack of proper parameter validation and handling, particularly for required fields like `priority_id`.

## Identified Root Causes

1. **Missing Required Parameters**: The Redmine API requires certain fields (particularly `priority_id`) that weren't being properly passed through the MCP interface.

2. **Error Handling**: The error responses from the Redmine API weren't being properly captured and displayed.

3. **Parameter Validation**: Insufficient validation of parameters before sending the request to Redmine.

## Implemented Fixes

1. ✅ **Enhanced RedmineClient.ts**:
   - Added comprehensive parameter validation
   - Improved error handling with detailed logging
   - Added type checking and conversion for all parameters
   - Enhanced error reporting to capture detailed API responses

2. ✅ **Updated MCP Server Tool Definition**:
   - Implemented robust parameter validation
   - Added parameter type conversion to ensure correct formats
   - Enhanced error response structure to include all relevant details
   - Added detailed logging of parameters for debugging

3. ✅ **Created Diagnostic Tools**:
   - `test-issue-creation.js`: Tests direct API client functionality
   - `direct-api-call.sh`: Tests direct Redmine API communication
   - `test-minimal-issue.js` and `test-esm-mcp.js`: Tests MCP protocol commands
   - `database-diagnosis.sql`: SQL queries to check database configuration

## Verification Results

The fixes have been verified through the following tests:

1. **Direct API Tests**: Successfully created issues via curl commands with the required fields.

2. **TypeScript Client Tests**: Successfully created and updated issues through the API client.

3. **MCP Protocol Tests**: Successfully created and updated issues through Claude's MCP interface.

## Best Practices

When working with the Redmine MCP integration, follow these best practices:

1. **Always Include Required Fields**:
   - `project_id` (required)
   - `subject` (required)
   - `priority_id` (required in Redmine's implementation)
   - `tracker_id` (optional but recommended)

2. **Verify Parameter Types**:
   - All IDs should be numbers
   - Strings should be properly encoded

3. **Check Error Responses**:
   - Detailed error messages are now available in the response

## Next Steps (TODO)

1. **Integration Tests**: Create automated tests to verify the integration between Claude and Redmine
2. **Documentation Update**: Update user documentation to specify required parameters
3. **MCP Protocol Research**: Investigate MCP protocol changes between versions
4. **Retry Mechanism**: Add retry logic for transient API errors
5. **Parameter Validation**: Add schema validation for all incoming parameters
6. **Error Handling**: Improve user-facing error messages
7. **Performance Optimization**: Add caching for frequently accessed resources

## Conclusion

The issue has been successfully resolved by adding proper parameter validation and error handling. Direct tests through the Claude MCP interface confirm that issues can now be created and updated without errors when the required parameters are included.
