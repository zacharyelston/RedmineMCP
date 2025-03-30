# TODO List for Redmine MCP Extension

This document outlines planned enhancements and features for the Redmine Model Context Protocol Extension.

## High Priority

- [x] **Credentials Management System**
  - [x] Create a credentials.yaml file template for storing API keys and connection details
  - [x] Implement system to load credentials from the YAML file
  - [x] Add credentials.yaml to .gitignore to prevent accidental commits
  - [x] Update documentation with instructions on credential configuration

- [x] **Redmine Development Container**
  - [x] Create a Docker container with a pre-configured Redmine instance for development
  - [x] Include automatic setup of test projects, users, and issues
  - [x] Configure the container to initialize with consistent test data
  - [x] Add documentation for container usage
  - [ ] Create pre-configured database with trackers and required entities for simplified testing (#19)

- [x] **Test API Connection Functionality**
  - [x] Implement real connection testing for Redmine and Claude APIs
  - [x] Add detailed error reporting for API connection issues
  - [x] Create visual indicators for connection status
  - [ ] Create comprehensive automated test script for validating Redmine API functionality
  - [ ] Fix tracker configuration in Redmine API testing (#19)

- [ ] **Improved Error Handling**
  - Add more detailed error messages
  - Implement graceful fallbacks when APIs are unavailable
  - Create a dedicated error logging view

- [ ] **User Authentication**
  - Add user login/registration system
  - Implement role-based permissions
  - Secure API endpoints with token authentication

## Medium Priority

- [x] **Enhanced LLM Features**
  - [x] Add support for Claude API (migrated from OpenAI)
  - [x] Add support for OpenAI API with gpt-4o model
  - [x] Implement context-aware prompts that understand Redmine's workflow
  - [x] Create specialized prompt templates for different issue types
  - [x] Create Claude desktop configuration for easy integration
  - [x] Create LLM factory pattern to abstract provider differences

- [ ] **Redmine Integration Improvements**
  - Support for Redmine custom fields
  - Add ability to attach files to issues
  - Integration with Redmine wiki for documentation generation

- [ ] **Advanced Analytics**
  - Create dashboard with usage statistics
  - Add visualizations for LLM performance metrics
  - Track time saved through automation

## Low Priority

- [ ] **UI/UX Enhancements**
  - Add dark/light theme toggle
  - Improve mobile responsiveness
  - Create a guided setup wizard for first-time users

- [ ] **Webhooks and Automation**
  - Set up webhook triggers for Redmine events
  - Create automation rules for issue updates
  - Implement scheduled tasks (e.g., daily issue summary)

- [ ] **Export and Reporting**
  - Add CSV/PDF export for logs and statistics
  - Create scheduled email reports
  - Generate usage summaries for billing purposes

## Technical Debt

- [ ] **Code Refactoring**
  - Improve test coverage
  - Optimize database queries
  - Refactor API client code for better maintainability

- [ ] **Documentation**
  - Create API documentation with Swagger/OpenAPI
  - Add detailed developer documentation
  - Create user manual with examples

- [x] **MCP Integration**
  - [x] Implement Model Context Protocol endpoints
  - [x] Create MCP-compatible API responses
  - [x] Add Claude Desktop configuration
  - [x] Create local development Docker setup
  - [ ] Test with Claude Desktop client

- [x] **DevOps**
  - [x] Set up CI/CD pipeline (basic GitHub Actions)
  - [x] Create Docker container for easy deployment
  - [ ] Add monitoring and alerting
  - [x] Set up GitHub Actions workflows
    - [x] Implement workflow for running tests
    - [x] Add workflow for automated linting and code quality
      - [x] Create config validation script (scripts/validate_configs.py)
      - [x] Create automated branch and commit script with validation
    - [x] Create workflow for building and publishing Docker images
    - [ ] Set up deployment workflow for staging/production environments
    - [x] Add script to check GitHub Actions build results from Replit
    - [x] Fix package installation issues in GitHub Actions workflows
    - [x] Enhance compatibility with ARM64 architecture
      - [x] Replace MySQL with MariaDB in CI environment
      - [x] Add ARM64 compatibility testing script
      - [x] Update CI workflows for cross-platform support

## Future Considerations

- [ ] **Multi-Tenant Support**
  - Allow multiple Redmine instances to be connected
  - Implement organization accounts with shared settings
  - Add billing/usage tracking per tenant

- [ ] **Extended AI Capabilities**
  - Implement predictive analytics for issue resolution time
  - Add sentiment analysis for issue comments
  - Create AI-powered project planning suggestions

- [ ] **Integration with Other Systems**
  - Connect with version control systems (Git, SVN)
  - Integrate with chat platforms (Slack, Discord, Teams)
  - Add support for other project management tools