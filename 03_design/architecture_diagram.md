# RedmineMCP System Architecture

```
+---------------------------+            +--------------------+
|                           |            |                    |
|  AI Assistant / LLM       |            |  Redmine Instance  |
|                           |            |                    |
+-----------+---------------+            +----------+---------+
            |                                       |
            | MCP Client Protocol                   | REST API
            |                                       |
            v                                       v
+---------------------------+            +--------------------+
|                           |            |                    |
|  RedmineMCP Server        +<-----------+  Redmine API      |
|                           |            |  Client           |
+---------------------------+            +--------------------+
    |         |         |
    |         |         |
    v         v         v
+--------+ +--------+ +--------+
|        | |        | |        |
|Resource| |Tools   | |Prompts |
|Handler | |Handler | |Handler |
|        | |        | |        |
+--------+ +--------+ +--------+
    |         |         |
    v         v         v
+---------------------------+
|                           |
|  Resource/Schema Registry |
|                           |
+---------------------------+
```

## Component Descriptions

### External Systems

#### AI Assistant / LLM
- Interacts with the RedmineMCP Server via the MCP Client Protocol
- Consumes resources, calls tools, and uses prompts provided by the MCP server
- Examples include: Claude, GPT, or other AI assistants that support the MCP protocol

#### Redmine Instance
- The existing Redmine project management application
- Exposes its data and functionality via a REST API
- Stores all project management data (issues, projects, users, etc.)

### Core Components

#### RedmineMCP Server
- Implements the MCP Server specification
- Acts as a bridge between AI assistants and Redmine
- Routes requests to appropriate handlers
- Manages connections and authentication

#### Redmine API Client
- Handles communication with the Redmine REST API
- Manages authentication via API keys
- Translates between MCP and Redmine data formats
- Handles API errors and retries

### Functional Handlers

#### Resource Handler
- Exposes Redmine data as MCP resources
- Implements resource listing, reading, and subscription
- Manages resource templates for dynamic resource access
- Examples: projects, issues, wiki pages, documents

#### Tools Handler
- Implements MCP tools that perform actions in Redmine
- Manages tool execution, error handling, and results
- Examples: create issue, update status, add comment, log time

#### Prompts Handler
- Provides pre-defined prompt templates for common tasks
- Implements prompt parameter interpolation
- Examples: issue analysis, project reporting, documentation generation

### Supporting Components

#### Resource/Schema Registry
- Maintains definitions of all resources, tools, and prompts
- Provides schema validation for requests and responses
- Centralizes metadata about available capabilities

## Data Flow

1. An AI assistant connects to the RedmineMCP Server via MCP protocol
2. The server authenticates the client and reports its capabilities
3. The client requests resources or calls tools
4. The server routes requests to appropriate handlers
5. Handlers process requests, communicating with Redmine via the API client
6. Results are returned to the client following MCP protocol specifications

## Authentication Flow

1. RedmineMCP Server is configured with Redmine API credentials
2. Server authenticates with Redmine during initialization
3. AI assistants authenticate with the MCP server
4. All requests to Redmine are made with proper authentication

## Error Handling

1. Redmine API errors are translated to appropriate MCP error responses
2. Network issues trigger retry mechanisms
3. Invalid requests receive standardized error responses
4. All errors are logged for troubleshooting

## Deployment Architecture

The system can be deployed in various configurations:

1. As a standalone service connecting to a Redmine instance
2. As a plugin within the Redmine application itself
3. As a cloud service connecting to multiple Redmine instances

Each deployment model has different security and performance implications that should be considered during implementation.
