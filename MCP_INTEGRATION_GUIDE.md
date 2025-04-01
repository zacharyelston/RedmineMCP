# MCP Integration Guide for Redmine

*Note: Ideally, this file should be in a `docs/` directory.*

This guide explains how to use the Model Context Protocol (MCP) extension with Redmine to leverage AI capabilities for project management.

## Overview

The RedmineMCP extension integrates Large Language Models (LLMs) with Redmine to provide AI-assisted issue management through the Model Context Protocol (MCP).

## Key Features

- **AI-Powered Issue Creation**: Generate well-structured Redmine issues from natural language descriptions
- **Intelligent Issue Updates**: Update existing issues using natural language commands
- **Issue Analysis**: Get AI-powered insights and recommendations for existing issues

## Prerequisites

Before using the MCP integration:

1. Ensure Redmine is properly set up with:
   - Issue priorities (low, medium, high)
   - Issue trackers (Bug, Feature, Support)
   - Time tracking activities (dev, review, waiting)
   
2. Make sure your `credentials.yaml` file is configured with:
   - Redmine URL and API key
   - LLM provider API key
   - Rate limiting settings

## Using the MCP API

### Creating Issues with AI

Use natural language to create structured issues:

```bash
curl -X POST "http://localhost:9000/api/llm/create_issue" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Create a bug report for a login page issue where users are experiencing 404 errors after submitting login credentials on the production environment"}'
```

### Updating Issues with AI

Update existing issues with natural language:

```bash
curl -X POST "http://localhost:9000/api/llm/update_issue/123" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Change the priority to high and add more information about the browser versions affected"}'
```

### Analyzing Issues with AI

Get AI-powered analysis of existing issues:

```bash
curl -X POST "http://localhost:9000/api/llm/analyze_issue/123" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Best Practices

1. **Start with Clear Prompts**: Be specific in your natural language requests
2. **Review AI Output**: Always review AI-generated content before finalizing
3. **Use Structured Templates**: Develop consistent prompt templates for common tasks
4. **Be Aware of Rate Limits**: The MCP extension includes rate limiting to prevent API overuse
5. **Combine with Manual Work**: Use AI for initial creation and routine updates

## Troubleshooting

### API Connection Issues
- Verify your Redmine URL and API key in credentials.yaml
- Check if Redmine's REST API is enabled in Administration settings
- Ensure the MCP service is running on the expected port

### LLM Response Quality Issues
- Try providing more detailed prompts
- Check if you're hitting token limits with large issues
- Verify your LLM API key and provider settings
