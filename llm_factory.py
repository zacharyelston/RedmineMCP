"""
LLM Factory for Redmine Extension.
This module provides factory functions to create the appropriate LLM API client.
"""

import logging
import os
from llm_api import LLMAPI
from config import get_config

logger = logging.getLogger(__name__)

class MockLLMAPI:
    """
    A mock implementation of the LLM API for development and testing
    """
    
    def __init__(self):
        logger.info("Using Mock LLM API (for development/testing)")
    
    def generate_issue(self, prompt):
        """Mock implementation of generate_issue"""
        logger.info(f"MOCK LLM: Generating issue from prompt: {prompt[:50]}...")
        
        # Return a mock response
        return {
            "subject": f"Mock issue created from prompt: {prompt[:30]}...",
            "description": f"This is a mock issue generated for development testing.\n\nOriginal prompt: {prompt}",
            "tracker_id": 1,  # Bug
            "priority_id": 2  # Normal
        }
    
    def update_issue(self, prompt, current_issue):
        """Mock implementation of update_issue"""
        logger.info(f"MOCK LLM: Updating issue with prompt: {prompt[:50]}...")
        
        # Return a mock response
        return {
            "notes": f"Mock update note: {prompt[:100]}...",
            "priority_id": 3  # High (as an example change)
        }
    
    def analyze_issue(self, issue):
        """Mock implementation of analyze_issue"""
        logger.info(f"MOCK LLM: Analyzing issue #{issue.get('id', 'unknown')}")
        
        # Return a mock analysis
        return {
            "summary": f"Mock analysis of issue #{issue.get('id', 'unknown')} - {issue.get('subject', 'unknown')}",
            "root_causes": ["Mock root cause 1", "Mock root cause 2"],
            "suggested_actions": ["Mock suggestion 1", "Mock suggestion 2"],
            "complexity": "Medium",
            "recommended_priority": "High",
            "patterns": ["Mock pattern"],
            "additional_insights": "This is a mock analysis generated for development testing."
        }

def create_llm_client():
    """
    Create the LLM client based on configuration
    
    Returns:
        object: An instance of the LLM API client
    """
    # Get configuration from file
    config = get_config()
    llm_provider = config.get('llm_provider', 'claude-desktop')
    
    # Check for MOCK_LLM environment variable (for testing)
    mock_llm = os.environ.get('MOCK_LLM', '').lower() in ('true', '1', 'yes')
    
    if mock_llm:
        logger.info("Using mock LLM client due to MOCK_LLM environment variable")
        return MockLLMAPI()
    
    # Use mock implementation if configured in credentials.yaml
    if llm_provider == 'mock':
        logger.info("Using mock LLM client as configured in credentials.yaml")
        return MockLLMAPI()
    # Default to Claude Desktop MCP connection
    elif not llm_provider or llm_provider == 'claude-desktop':
        logger.info("Using ClaudeDesktop via MCP connection as the LLM provider")
        # MCP URL can be customized based on config
        mcp_url = config.get('mcp_url')
        
        # Check if MCP URL is the same as our own server (would cause infinite loop)
        server_config = config.get('server', {})
        own_host = server_config.get('host', '0.0.0.0')
        own_port = server_config.get('port', 9000)
        
        # Check for potential self-reference
        if mcp_url and ("localhost" in mcp_url or "127.0.0.1" in mcp_url) and str(own_port) in mcp_url:
            logger.warning("Detected self-reference in MCP URL, using mock LLM client to avoid infinite loop")
            return MockLLMAPI()
            
        return LLMAPI(mcp_url=mcp_url)
    else:
        # If we get here, it means the user has selected an unsupported LLM provider
        logger.error(f"Unsupported LLM provider: {llm_provider}")
        raise ValueError(f"Unsupported LLM provider: {llm_provider}. Currently only 'claude-desktop' and 'mock' are supported.")