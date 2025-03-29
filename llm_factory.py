"""
LLM Factory for Redmine Extension.
This module provides factory functions to create the appropriate LLM API client.
"""

import logging
from llm_api import LLMAPI
from config import get_config

logger = logging.getLogger(__name__)

def create_llm_client():
    """
    Create the LLM client for ClaudeDesktop MCP connection using file-based configuration
    
    Returns:
        object: An instance of the LLM API client
    """
    # Get configuration from file
    config = get_config()
    llm_provider = config.get('llm_provider', 'claude-desktop')
    
    if not llm_provider or llm_provider == 'claude-desktop':
        logger.info("Using ClaudeDesktop via MCP connection as the LLM provider")
        # MCP URL can be customized based on config
        mcp_url = config.get('mcp_url')
        
        return LLMAPI(mcp_url=mcp_url)
    else:
        # If we get here, it means the user has selected an unsupported LLM provider
        logger.error(f"Unsupported LLM provider: {llm_provider}")
        raise ValueError(f"Unsupported LLM provider: {llm_provider}. Currently only 'claude-desktop' is supported.")