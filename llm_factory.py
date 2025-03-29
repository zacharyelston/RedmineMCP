"""
LLM Factory for Redmine Extension.
This module provides factory functions to create the appropriate LLM API client.
"""

import logging
from llm_api import LLMAPI

logger = logging.getLogger(__name__)

def create_llm_client(config=None):
    """
    Create the LLM client for ClaudeDesktop MCP connection
    
    Args:
        config (models.Config, optional): The application configuration
        
    Returns:
        object: An instance of the LLM API client
    """
    if not config or not hasattr(config, 'llm_provider') or config.llm_provider == 'claude-desktop':
        logger.info("Using ClaudeDesktop via MCP connection as the LLM provider")
        # MCP URL can be customized based on config
        mcp_url = None
        if config and hasattr(config, 'mcp_url') and config.mcp_url:
            mcp_url = config.mcp_url
        
        return LLMAPI(mcp_url=mcp_url)
    else:
        # If we get here, it means the user has selected an unsupported LLM provider
        logger.error(f"Unsupported LLM provider: {config.llm_provider}")
        raise ValueError(f"Unsupported LLM provider: {config.llm_provider}. Currently only 'claude-desktop' is supported.")