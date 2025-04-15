# Redmine MCP Server - TODO List

## MVP Requirements (Current Focus)

### Database Setup (RMCP-20250411-03) ✓
- [x] Create Flyway migration structure
- [x] Create incremental database migrations
- [x] Set up user management and API keys
- [x] Add sample data for testing
- [x] Create Docker Compose configuration
- [x] Provide validation script
- [x] Document predefined API keys for development environment

### Initial Setup (RMCP-20250415-01)
- [x] Create directory structures
- [x] Create basic configuration files
- [x] Document setup process
- [x] Create credential management system
- [ ] Setup Node.js project structure
- [ ] Create basic MCP server
- [ ] Implement simple Redmine API client
- [ ] Validate initial setup

### Core Functionality (RMCP-20250416-01)
- [ ] Implement basic project listing
- [ ] Implement simple issue listing
- [ ] Create minimal command handlers
- [ ] Add basic error handling
- [ ] Test against Redmine instance

### Integration (RMCP-20250417-01)
- [ ] Test with Claude Desktop
- [ ] Create simple example commands
- [ ] Document basic usage
- [ ] Validate integration

## Future Ideas (Not Part of MVP)

The following are ideas for future development after the MVP is working:

- Advanced issue management
- User operations
- Time tracking
- Search capabilities
- Custom field support
- Reporting features
- Docker deployment
- Plugin system
- Monitoring and metrics

These items should only be considered after the MVP is successfully implemented, tested, and validated.

---

## Development Approach

- Focus on getting a minimal working product first
- Follow the process-driven approach outlined in PROCESS.md
- Document before implementing
- Test and validate each step
- Only move to the next task when current one is complete

## Development Environment

The Redmine server component (in `/redmine-server/`) provides a consistent development environment with predefined API keys:

| User     | API Key                                  | Role      |
|----------|------------------------------------------|-----------|
| admin    | 7a4ed5c91b405d30fda60909dbc86c2651c38217 | Admin     |
| testuser | 3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0 | Reporter  |
| developer| f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f | Developer |
| manager  | 5c98f85a9f2e34c3b217758e910e196c7a77bf5b | Manager   |

These API keys can be referenced in the `credentials.yaml` file for integration testing.

Remember: Process is the key and provides security through repetition. Start small and build up incrementally.
