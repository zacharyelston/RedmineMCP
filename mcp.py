"""
Model Context Protocol (MCP) integration for Redmine Extension.
This module defines MCP-specific endpoints and functionality.
"""

import json
import logging
from flask import Blueprint, request, jsonify
from models import Config
from redmine_api import RedmineAPI
from llm_api import LLMAPI
from utils import is_rate_limited, add_api_call

logger = logging.getLogger(__name__)

# Create a Flask Blueprint for MCP-specific routes
mcp = Blueprint('mcp', __name__)

@mcp.route('/api/capabilities', methods=['GET'])
def mcp_capabilities():
    """
    Standard MCP endpoint that returns the capabilities of this extension.
    This follows the MCP specification for capability discovery.
    """
    return jsonify({
        "id": "redmine-mcp-extension",
        "name": "Redmine MCP Extension",
        "description": "A Model Context Protocol extension for Redmine that uses Claude to manage issues",
        "version": "1.0.0",
        "publisher": "Anthropic Authorized Developer",
        "contact": "https://github.com/yourusername/redmine-mcp",
        "capabilities": [
            {
                "name": "issue_creation",
                "description": "Create Redmine issues from natural language prompts",
                "endpoint": "/api/llm/create_issue",
                "method": "POST"
            },
            {
                "name": "issue_update",
                "description": "Update existing Redmine issues from natural language prompts",
                "endpoint": "/api/llm/update_issue/{issue_id}",
                "method": "POST"
            },
            {
                "name": "issue_analyze",
                "description": "Analyze Redmine issues for insights",
                "endpoint": "/api/llm/analyze_issue/{issue_id}",
                "method": "POST"
            }
        ],
        "auth": {
            "type": "api_key",
            "config": {
                "in": "header",
                "name": "X-API-Key"
            }
        }
    })

@mcp.route('/api/health', methods=['GET'])
def mcp_health():
    """
    Health check endpoint for the MCP integration.
    Returns status of connections to Redmine and Claude APIs.
    """
    config = Config.query.first()
    
    if not config:
        return jsonify({
            "status": "warning",
            "message": "Configuration not found. Setup is required.",
            "services": {
                "redmine": {"status": "not_configured"},
                "claude": {"status": "not_configured"}
            }
        })
    
    # Check Redmine connectivity
    redmine_status = {"status": "unknown"}
    try:
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        # Just a simple API check
        redmine_api.get_projects()
        redmine_status = {"status": "healthy"}
    except Exception as e:
        redmine_status = {
            "status": "unhealthy", 
            "message": str(e)
        }
    
    # Check Claude API connectivity
    claude_status = {"status": "unknown"}
    try:
        # We'll just create the client to check if the key format is valid
        # A full test would require an actual API call which costs money
        llm_api = LLMAPI(config.claude_api_key)
        claude_status = {"status": "configured"}
    except Exception as e:
        claude_status = {
            "status": "unhealthy", 
            "message": str(e)
        }
    
    # Determine overall status
    overall_status = "healthy"
    if redmine_status["status"] != "healthy":
        overall_status = "warning" if redmine_status["status"] == "unknown" else "unhealthy"
    elif claude_status["status"] != "configured" and claude_status["status"] != "healthy":
        overall_status = "warning"
    
    return jsonify({
        "status": overall_status,
        "services": {
            "redmine": redmine_status,
            "claude": claude_status
        }
    })

# Function to register MCP blueprints to main Flask app
def register_mcp(app):
    """Register MCP blueprint with the Flask app"""
    app.register_blueprint(mcp)
    logger.info("MCP blueprint registered")