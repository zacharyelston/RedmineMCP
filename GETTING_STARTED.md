# Getting Started with Redmine MCP

This guide will help you set up and start using the Redmine MCP integration with Claude.

## Prerequisites

Before you begin, make sure you have:

- Node.js 18 or higher
- npm or yarn
- A Redmine instance with API access
- Claude Desktop application

## Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/redmine-mcp.git
cd redmine-mcp
```

## Step 2: Set Up the Redmine Development Environment (Optional)

If you don't have a Redmine instance, you can use the included development environment:

```bash
cd redmine-server
docker-compose up -d
```

This will start a local Redmine instance at http://localhost:3000 with the following credentials:
- Username: admin
- Password: admin
- API Key: 7a4ed5c91b405d30fda60909dbc86c2651c38217

## Step 3: Configure the MCP Server

1. Navigate to the TypeScript implementation directory:
   ```bash
   cd redmcp-typescript
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file with your Redmine configuration:
   ```
   REDMINE_URL=http://localhost:3000
   REDMINE_API_KEY=7a4ed5c91b405d30fda60909dbc86c2651c38217
   LOG_LEVEL=info
   # SERVER_MODE=mock  # Uncomment to enable mock mode for development without Redmine
   ```

   If you're using your own Redmine instance, replace the URL and API key with your own values.

4. Build the TypeScript code:
   ```bash
   npm run build
   ```

## Step 4: Start the MCP Server

```bash
npm start
```

You should see output similar to:
```
[INFO] Redmine MCP server starting at 2025-04-14T22:36:09.455Z
[INFO] Node.js version: v22.14.0
[INFO] Redmine URL: http://localhost:3000
[INFO] Using Redmine client
[INFO] Successfully connected to Redmine
[INFO] Redmine MCP server running - Connected to stdio transport
```

## Step 5: Configure Claude Desktop

1. Open Claude Desktop
2. Go to Settings > MCP Servers
3. Add a new MCP server with the following configuration:

```json
{
  "mcpServers": {
    "redmine": {
      "command": "node",
      "args": ["/absolute/path/to/redmcp-typescript/build/index.js"],
      "env": {
        "REDMINE_URL": "http://localhost:3000",
        "REDMINE_API_KEY": "7a4ed5c91b405d30fda60909dbc86c2651c38217",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

Replace `/absolute/path/to/` with the actual path to your cloned repository.

Example configuration files can be found in the `redmcp-typescript/docs/` directory.

## Step 6: Test the Integration

1. Start a new conversation in Claude Desktop
2. Try asking Claude to perform Redmine operations, such as:
   - "List all Redmine projects"
   - "Show me the details of the MCP Project"
   - "Create a new issue in the MCP Project with priority 2"
   - "Show me my user information in Redmine"

## Available MCP Tools

Here are some examples of how to use the available MCP tools:

### List Projects
```
Can you list all the projects in Redmine?
```

### Get Project Details
```
Show me details about the project with identifier "mcp-project".
```

### List Issues
```
List the most recent issues in the MCP Project.
```

### Create Issue
```
Create a new issue in project ID 1 with subject "Test issue" and priority ID 2.
```

### Update Issue
```
Update issue ID 1 to change its subject to "Updated issue title" and set its priority to high (ID 3).
```

### Get User Information
```
Show me information about my Redmine user account.
```

## Troubleshooting

If you encounter issues:

1. Check the Claude Desktop logs (Menu > Help > Show Logs)
2. Verify that the MCP server is running and connected to Redmine
3. Ensure your API key has appropriate permissions in Redmine
4. Consult the `TROUBLESHOOTING.md` file in the `redmcp-typescript` directory

For detailed information about parameter requirements and error handling, refer to the [redmcp-typescript README](./redmcp-typescript/README.md).

## Next Steps

After you have the basic integration working, you might want to:

1. Create automated tests for your most common operations
2. Implement additional MCP tools for more advanced Redmine features
3. Set up a production deployment with proper security considerations
4. Contribute improvements to the project

For future development plans, see the [TODO.md](./redmcp-typescript/TODO.md) file.
