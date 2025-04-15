# ModelContextProtocol (MCP) Specification

## Version Information
- **Document Version:** 0.1
- **Date:** 2025-04-10
- **Author:** Project Manager
- **Status:** Draft

## 1. Introduction

### 1.1 Purpose
This document defines the ModelContextProtocol (MCP) specification for the Redmine MCP Server. The protocol provides a standardized interface for model context management within Redmine.

### 1.2 Scope
This specification covers:
- Protocol message format
- Protocol commands
- Protocol validation rules
- Protocol error handling
- Redmine-specific protocol extensions

### 1.3 Terminology
- **MCP**: ModelContextProtocol
- **Command**: An operation requested by a client
- **Response**: Data returned by the server in response to a command
- **Entity**: A data object managed by the system
- **Context**: Environment and state information for a model
- **Model**: A computational representation used for processing
- **Client**: A system that sends commands to the MCP server
- **Server**: The MCP server that processes commands and returns responses

## 2. Protocol Overview

### 2.1 Protocol Principles
1. **Stateless**: Each command contains all necessary information
2. **Verifiable**: All commands can be validated for correctness
3. **Secure**: All operations require proper authentication
4. **Traceable**: All operations are logged for audit purposes
5. **Extensible**: The protocol can be extended for specific use cases

### 2.2 Message Format
All MCP messages use JSON format with UTF-8 encoding. Each message has a standard envelope structure:

```json
{
  "meta": {
    "protocol": "MCP",
    "version": "1.0",
    "requestId": "unique-request-identifier",
    "timestamp": "ISO-8601-timestamp"
  },
  "auth": {
    "token": "authentication-token",
    "method": "authentication-method"
  },
  "command": {
    "name": "command-name",
    "parameters": {
      // Command-specific parameters
    }
  }
}
```

### 2.3 Response Format
All MCP responses use JSON format with UTF-8 encoding. Each response has a standard envelope structure:

```json
{
  "meta": {
    "protocol": "MCP",
    "version": "1.0",
    "requestId": "original-request-identifier",
    "timestamp": "ISO-8601-timestamp",
    "processingTime": "milliseconds"
  },
  "status": {
    "code": "status-code",
    "message": "human-readable-message"
  },
  "data": {
    // Response data
  }
}
```

### 2.4 Command Categories
1. **Model Commands**: Operations related to computational models
2. **Context Commands**: Operations related to model contexts
3. **Entity Commands**: Operations related to data entities
4. **System Commands**: Operations related to system management
5. **Redmine Commands**: Redmine-specific operations

## 3. Command Specification

### 3.1 Model Commands

#### 3.1.1 model.create
Creates a new model.

**Parameters:**
```json
{
  "name": "model-name",
  "type": "model-type",
  "description": "model-description",
  "properties": {
    // Model-specific properties
  }
}
```

**Response:**
```json
{
  "modelId": "unique-model-identifier",
  "name": "model-name",
  "type": "model-type",
  "createdAt": "ISO-8601-timestamp"
}
```

#### 3.1.2 model.get
Retrieves model information.

**Parameters:**
```json
{
  "modelId": "model-identifier"
}
```

**Response:**
```json
{
  "modelId": "model-identifier",
  "name": "model-name",
  "type": "model-type",
  "description": "model-description",
  "properties": {
    // Model-specific properties
  },
  "createdAt": "ISO-8601-timestamp",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.1.3 model.update
Updates model information.

**Parameters:**
```json
{
  "modelId": "model-identifier",
  "name": "updated-model-name",
  "description": "updated-model-description",
  "properties": {
    // Updated model-specific properties
  }
}
```

**Response:**
```json
{
  "modelId": "model-identifier",
  "name": "updated-model-name",
  "type": "model-type",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.1.4 model.delete
Deletes a model.

**Parameters:**
```json
{
  "modelId": "model-identifier"
}
```

**Response:**
```json
{
  "modelId": "model-identifier",
  "status": "deleted",
  "deletedAt": "ISO-8601-timestamp"
}
```

#### 3.1.5 model.list
Lists available models.

**Parameters:**
```json
{
  "filter": {
    "type": "model-type",
    "name": "name-pattern",
    "createdAfter": "ISO-8601-timestamp",
    "createdBefore": "ISO-8601-timestamp"
  },
  "pagination": {
    "offset": 0,
    "limit": 10
  },
  "sort": {
    "field": "name",
    "direction": "asc"
  }
}
```

**Response:**
```json
{
  "models": [
    {
      "modelId": "model-identifier-1",
      "name": "model-name-1",
      "type": "model-type-1",
      "description": "model-description-1",
      "createdAt": "ISO-8601-timestamp"
    },
    // Additional models
  ],
  "pagination": {
    "offset": 0,
    "limit": 10,
    "total": 42
  }
}
```

### 3.2 Context Commands

#### 3.2.1 context.create
Creates a new context.

**Parameters:**
```json
{
  "modelId": "model-identifier",
  "name": "context-name",
  "description": "context-description",
  "parameters": {
    // Context-specific parameters
  },
  "dataSourceId": "data-source-identifier"
}
```

**Response:**
```json
{
  "contextId": "unique-context-identifier",
  "modelId": "model-identifier",
  "name": "context-name",
  "createdAt": "ISO-8601-timestamp"
}
```

#### 3.2.2 context.get
Retrieves context information.

**Parameters:**
```json
{
  "contextId": "context-identifier"
}
```

**Response:**
```json
{
  "contextId": "context-identifier",
  "modelId": "model-identifier",
  "name": "context-name",
  "description": "context-description",
  "parameters": {
    // Context-specific parameters
  },
  "dataSourceId": "data-source-identifier",
  "createdAt": "ISO-8601-timestamp",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.2.3 context.update
Updates context information.

**Parameters:**
```json
{
  "contextId": "context-identifier",
  "name": "updated-context-name",
  "description": "updated-context-description",
  "parameters": {
    // Updated context-specific parameters
  }
}
```

**Response:**
```json
{
  "contextId": "context-identifier",
  "modelId": "model-identifier",
  "name": "updated-context-name",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.2.4 context.delete
Deletes a context.

**Parameters:**
```json
{
  "contextId": "context-identifier"
}
```

**Response:**
```json
{
  "contextId": "context-identifier",
  "status": "deleted",
  "deletedAt": "ISO-8601-timestamp"
}
```

#### 3.2.5 context.list
Lists available contexts.

**Parameters:**
```json
{
  "filter": {
    "modelId": "model-identifier",
    "name": "name-pattern",
    "createdAfter": "ISO-8601-timestamp",
    "createdBefore": "ISO-8601-timestamp"
  },
  "pagination": {
    "offset": 0,
    "limit": 10
  },
  "sort": {
    "field": "name",
    "direction": "asc"
  }
}
```

**Response:**
```json
{
  "contexts": [
    {
      "contextId": "context-identifier-1",
      "modelId": "model-identifier-1",
      "name": "context-name-1",
      "description": "context-description-1",
      "createdAt": "ISO-8601-timestamp"
    },
    // Additional contexts
  ],
  "pagination": {
    "offset": 0,
    "limit": 10,
    "total": 23
  }
}
```

### 3.3 Entity Commands

#### 3.3.1 entity.create
Creates a new entity.

**Parameters:**
```json
{
  "type": "entity-type",
  "name": "entity-name",
  "description": "entity-description",
  "attributes": {
    // Entity-specific attributes
  },
  "relationships": [
    {
      "type": "relationship-type",
      "targetId": "related-entity-identifier",
      "properties": {
        // Relationship-specific properties
      }
    }
  ]
}
```

**Response:**
```json
{
  "entityId": "unique-entity-identifier",
  "type": "entity-type",
  "name": "entity-name",
  "createdAt": "ISO-8601-timestamp"
}
```

#### 3.3.2 entity.get
Retrieves entity information.

**Parameters:**
```json
{
  "entityId": "entity-identifier"
}
```

**Response:**
```json
{
  "entityId": "entity-identifier",
  "type": "entity-type",
  "name": "entity-name",
  "description": "entity-description",
  "attributes": {
    // Entity-specific attributes
  },
  "relationships": [
    {
      "type": "relationship-type",
      "targetId": "related-entity-identifier",
      "properties": {
        // Relationship-specific properties
      }
    }
  ],
  "createdAt": "ISO-8601-timestamp",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.3.3 entity.update
Updates entity information.

**Parameters:**
```json
{
  "entityId": "entity-identifier",
  "name": "updated-entity-name",
  "description": "updated-entity-description",
  "attributes": {
    // Updated entity-specific attributes
  }
}
```

**Response:**
```json
{
  "entityId": "entity-identifier",
  "type": "entity-type",
  "name": "updated-entity-name",
  "updatedAt": "ISO-8601-timestamp"
}
```

#### 3.3.4 entity.delete
Deletes an entity.

**Parameters:**
```json
{
  "entityId": "entity-identifier"
}
```

**Response:**
```json
{
  "entityId": "entity-identifier",
  "status": "deleted",
  "deletedAt": "ISO-8601-timestamp"
}
```

#### 3.3.5 entity.list
Lists available entities.

**Parameters:**
```json
{
  "filter": {
    "type": "entity-type",
    "name": "name-pattern",
    "createdAfter": "ISO-8601-timestamp",
    "createdBefore": "ISO-8601-timestamp"
  },
  "pagination": {
    "offset": 0,
    "limit": 10
  },
  "sort": {
    "field": "name",
    "direction": "asc"
  }
}
```

**Response:**
```json
{
  "entities": [
    {
      "entityId": "entity-identifier-1",
      "type": "entity-type-1",
      "name": "entity-name-1",
      "description": "entity-description-1",
      "createdAt": "ISO-8601-timestamp"
    },
    // Additional entities
  ],
  "pagination": {
    "offset": 0,
    "limit": 10,
    "total": 105
  }
}
```

### 3.4 System Commands

#### 3.4.1 system.ping
Checks system availability.

**Parameters:**
```json
{
  "echo": "optional-echo-string"
}
```

**Response:**
```json
{
  "echo": "optional-echo-string",
  "serverTime": "ISO-8601-timestamp",
  "version": "server-version"
}
```

#### 3.4.2 system.status
Gets system status.

**Parameters:**
```json
{
  "includeMetrics": true,
  "includeVersions": true
}
```

**Response:**
```json
{
  "status": "ok",
  "uptime": "seconds",
  "serverTime": "ISO-8601-timestamp",
  "metrics": {
    "requestsProcessed": 12345,
    "averageResponseTime": 42,
    "activeConnections": 5
  },
  "versions": {
    "server": "server-version",
    "api": "api-version",
    "protocol": "protocol-version"
  }
}
```

#### 3.4.3 system.info
Gets system information.

**Parameters:**
```json
{
  "category": "optional-category"
}
```

**Response:**
```json
{
  "info": {
    "name": "Redmine MCP Server",
    "version": "server-version",
    "apiVersion": "api-version",
    "protocolVersion": "protocol-version",
    "supportedCommands": [
      "command-1",
      "command-2",
      // Additional commands
    ],
    "supportedAuthentication": [
      "auth-method-1",
      "auth-method-2",
      // Additional authentication methods
    ]
  }
}
```

### 3.5 Redmine Commands

#### 3.5.1 redmine.project.list
Lists Redmine projects.

**Parameters:**
```json
{
  "filter": {
    "name": "name-pattern",
    "identifier": "identifier-pattern",
    "status": "active"
  },
  "pagination": {
    "offset": 0,
    "limit": 10
  },
  "sort": {
    "field": "name",
    "direction": "asc"
  }
}
```

**Response:**
```json
{
  "projects": [
    {
      "id": "project-id-1",
      "name": "project-name-1",
      "identifier": "project-identifier-1",
      "description": "project-description-1",
      "status": "active",
      "createdOn": "ISO-8601-timestamp",
      "updatedOn": "ISO-8601-timestamp"
    },
    // Additional projects
  ],
  "pagination": {
    "offset": 0,
    "limit": 10,
    "total": 15
  }
}
```

#### 3.5.2 redmine.issue.list
Lists Redmine issues.

**Parameters:**
```json
{
  "filter": {
    "projectId": "project-id",
    "assignedTo": "user-id",
    "status": "open",
    "tracker": "tracker-id",
    "priority": "priority-id",
    "subject": "subject-pattern",
    "createdAfter": "ISO-8601-timestamp",
    "createdBefore": "ISO-8601-timestamp"
  },
  "pagination": {
    "offset": 0,
    "limit": 10
  },
  "sort": {
    "field": "updated_on",
    "direction": "desc"
  }
}
```

**Response:**
```json
{
  "issues": [
    {
      "id": "issue-id-1",
      "projectId": "project-id-1",
      "trackerId": "tracker-id-1",
      "statusId": "status-id-1",
      "priorityId": "priority-id-1",
      "subject": "issue-subject-1",
      "description": "issue-description-1",
      "assignedToId": "user-id-1",
      "createdOn": "ISO-8601-timestamp",
      "updatedOn": "ISO-8601-timestamp"
    },
    // Additional issues
  ],
  "pagination": {
    "offset": 0,
    "limit": 10,
    "total": 42
  }
}
```

#### 3.5.3 redmine.issue.create
Creates a Redmine issue.

**Parameters:**
```json
{
  "projectId": "project-id",
  "trackerId": "tracker-id",
  "statusId": "status-id",
  "priorityId": "priority-id",
  "subject": "issue-subject",
  "description": "issue-description",
  "assignedToId": "user-id",
  "customFields": [
    {
      "id": "custom-field-id-1",
      "value": "custom-field-value-1"
    },
    // Additional custom fields
  ]
}
```

**Response:**
```json
{
  "id": "issue-id",
  "projectId": "project-id",
  "trackerId": "tracker-id",
  "statusId": "status-id",
  "priorityId": "priority-id",
  "subject": "issue-subject",
  "description": "issue-description",
  "assignedToId": "user-id",
  "createdOn": "ISO-8601-timestamp"
}
```

## 4. Error Handling

### 4.1 Error Response Format
All error responses use the standard response format with appropriate status codes:

```json
{
  "meta": {
    "protocol": "MCP",
    "version": "1.0",
    "requestId": "original-request-identifier",
    "timestamp": "ISO-8601-timestamp",
    "processingTime": "milliseconds"
  },
  "status": {
    "code": "error-code",
    "message": "human-readable-error-message"
  },
  "error": {
    "type": "error-type",
    "details": {
      // Error-specific details
    },
    "trace": "optional-error-trace-for-debugging"
  }
}
```

### 4.2 Error Codes
- **400**: Bad Request - Invalid command or parameters
- **401**: Unauthorized - Authentication required
- **403**: Forbidden - Insufficient permissions
- **404**: Not Found - Resource not found
- **409**: Conflict - Resource conflict
- **422**: Unprocessable Entity - Semantic errors
- **429**: Too Many Requests - Rate limit exceeded
- **500**: Internal Server Error - Server error
- **503**: Service Unavailable - Server temporarily unavailable

### 4.3 Error Types
- **ValidationError**: Invalid input parameters
- **AuthenticationError**: Authentication failed
- **AuthorizationError**: Insufficient permissions
- **ResourceNotFoundError**: Resource not found
- **ConflictError**: Resource conflict
- **RateLimitError**: Rate limit exceeded
- **ServerError**: Internal server error
- **ServiceUnavailableError**: Service temporarily unavailable

## 5. Authentication and Authorization

### 5.1 Authentication Methods
- **apiKey**: API key authentication
- **oauth2**: OAuth 2.0 authentication
- **basic**: Basic authentication (username/password)

### 5.2 Authorization Model
Authorization is based on Redmine roles and permissions. Each command requires specific permissions to execute.

## 6. Protocol Extensions

### 6.1 Extension Mechanism
Protocol extensions follow the namespace convention `vendor.category.command`:

```json
{
  "command": {
    "name": "vendor.category.command",
    "parameters": {
      // Command-specific parameters
    }
  }
}
```

### 6.2 Redmine Extensions
Redmine-specific extensions use the `redmine` namespace:

```json
{
  "command": {
    "name": "redmine.category.command",
    "parameters": {
      // Command-specific parameters
    }
  }
}
```

## 7. Versioning

### 7.1 Protocol Versioning
The protocol version is specified in the `meta.version` field of each message:

```json
{
  "meta": {
    "protocol": "MCP",
    "version": "1.0",
    // Additional meta fields
  }
}
```

### 7.2 Version Compatibility
- **1.0**: Initial protocol version

## 8. Implementation Considerations

### 8.1 Security Considerations
- All communications should use TLS encryption
- API keys and tokens should be kept secure
- Input parameters should be properly validated
- Authentication and authorization should be enforced for all commands

### 8.2 Performance Considerations
- Commands should be processed efficiently
- Large responses should be paginated
- Rate limiting should be implemented
- Resource usage should be monitored

### 8.3 Scalability Considerations
- The protocol should support high concurrency
- The implementation should be horizontally scalable
- Stateless design facilitates load balancing

## 9. Appendix

### 9.1 JSON Schema
Complete JSON schema for protocol messages is provided separately.

### 9.2 Examples
Example request and response messages for common operations are provided separately.

---

## Approval
- [ ] Specification reviewed and approved
- [ ] Specification consistent with requirements
- [ ] Specification feasible for implementation