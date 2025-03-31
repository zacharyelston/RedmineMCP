# RedmineMCP Documentation Index

This document serves as an index to all documentation files for the RedmineMCP project.

*Note: Ideally, all these files should be organized in a `docs/` directory.*

## Project Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Main project overview and introduction |
| [TODO.md](TODO.md) | List of planned enhancements and features |
| [DEVELOPER-GUIDE.md](DEVELOPER-GUIDE.md) | Guide for developers working on the project |
| [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) | Current implementation status and progress |

## Redmine Integration Documentation

| Document | Description |
|----------|-------------|
| [REDMINE_API_NOTES.md](REDMINE_API_NOTES.md) | Practical knowledge and examples for working with Redmine API |
| [REDMINE_WORKFLOW_GUIDE.md](REDMINE_WORKFLOW_GUIDE.md) | Guide for establishing workflows in Redmine |

## MCP Extension Documentation

| Document | Description |
|----------|-------------|
| [MCP_INTEGRATION_GUIDE.md](MCP_INTEGRATION_GUIDE.md) | Guide for using the MCP extension with Redmine |

## Support Documentation

| Document | Description |
|----------|-------------|
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Solutions for common issues and challenges |

## Docker Documentation

The project includes several Docker-related files:
- `Dockerfile` - Main Dockerfile for the MCP extension
- `Dockerfile.redmine` - Dockerfile for Redmine
- `docker-compose.yml` - Main Docker Compose configuration
- `docker-compose.dev.yml` - Development environment configuration
- `docker-compose.local.yml` - Local development configuration

## Scripts

The `scripts/` directory contains various helper scripts:
- `bootstrap_redmine.py` - Script for configuring Redmine with essential setup
- `setup_redmine.sh` - Script for setting up Redmine in Docker
- `test_redmine_api_functionality.py` - Script for testing Redmine API
- And many more for specific tasks

## Contributing Documentation

To contribute to this documentation:

1. Ideally, create a `docs/` directory and organize all documentation there
2. Update this index when adding new documentation files
3. Follow the established Markdown formatting conventions
4. Ensure examples are up-to-date with the current codebase
5. Test any API examples before documenting them

## Documentation TODOs

- [ ] Create a proper `docs/` directory structure
- [ ] Add API documentation with OpenAPI/Swagger
- [ ] Create user guides with screenshots
- [ ] Add sequence diagrams for key workflows
- [ ] Create a troubleshooting decision tree
