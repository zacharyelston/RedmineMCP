# Redmine Architecture Overview

## Platform & Technology Stack

Redmine is built using the following key technologies:

- **Ruby on Rails Framework**: The core application is written in Ruby using the Rails framework as a "flexible project management web application".
- **Cross-Platform**: Redmine works across different operating systems and is "cross-platform and cross-database".
- **Cross-Database Compatibility**: Supports multiple database management systems.
- **Open Source**: Released under the GNU General Public License v2 (GPL) .

## Core Components

Redmine's architecture includes the following key components:

1. **Web Application Layer**: The user interface and application logic built on Rails.
2. **API Layer**: A REST API that exposes functionality to external systems.
3. **Database Layer**: Storage for projects, issues, users, and other entities.
4. **Plugin System**: Architecture that allows for extensions.

## REST API Architecture

Redmine provides a comprehensive REST API with the following characteristics:

- **API Format Support**: The API supports both XML and JSON formats for data exchange.
- **Authentication**: Most API operations require authentication, typically using an API key.
- **CRUD Operations**: The API provides access and basic CRUD operations (create, update, delete) for various resources.
- **Content Type Requirements**: When working with the API, the Content-Type of the request MUST be specified (application/json for JSON, application/xml for XML).

## Key API Endpoints

Redmine's REST API provides endpoints for various resources, including:

1. **Projects**: Managing project resources
2. **Issues**: Creating and updating tickets/issues
3. **Users**: User management
4. **Time Entries**: Tracking time spent on issues
5. **Custom Fields**: Managing custom fields for various entities

## Data Model

The Redmine data model is centered around:

1. **Projects**: Container for all other entities
2. **Issues**: Core tracking element for tasks, bugs, features
3. **Users/Members**: People involved in projects with specific roles
4. **Trackers**: Different types of issues (bugs, features, etc.)
5. **Custom Fields**: Extensible data attributes
6. **Time Entries**: Work time tracking records

## Integration Points for MCP

Potential integration points between Redmine and the Model Context Protocol include:

1. **Resource Access**: MCP servers could expose Redmine data as resources:
   - Projects
   - Issues
   - Wiki content
   - Documents
   - Forums

2. **Tool Integration**: MCP tools could be created to:
   - Create or update issues
   - Add comments to issues
   - Change issue status
   - Log time entries
   - Query for project information

3. **Prompt Templates**: MCP could provide prompt templates for common Redmine tasks:
   - Issue analysis
   - Project status reporting
   - Sprint planning
   - Issue summarization
