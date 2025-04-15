/**
 * Type definitions for MCP Server
 */

declare module '@modelcontextprotocol/sdk/server/mcp.js' {
  import { z } from 'zod';

  export class McpServer {
    constructor(options: { name: string; version: string });
    
    registerTool(toolDefinition: {
      name: string;
      description: string;
      schema: z.ZodType<any, any, any>;
      handler: (params: any) => Promise<any>;
    }): void;
    
    tool(
      name: string,
      schema: Record<string, z.ZodType<any, any, any>>,
      handler: (params: any) => Promise<any>
    ): void;
    
    connect(transport: any): Promise<void>;
  }
}
