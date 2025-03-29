"""
LLM Factory for Redmine Extension.
This module provides factory functions to create the appropriate LLM API client.
"""

import logging
from llm_api import LLMAPI

logger = logging.getLogger(__name__)

def create_llm_client(config):
    """
    Create the appropriate LLM client based on the configuration
    
    Args:
        config (models.Config): The application configuration
        
    Returns:
        object: An instance of the appropriate LLM API client
    """
    provider = config.llm_provider.lower()
    
    if provider == 'claude':
        if not config.claude_api_key:
            raise ValueError("Claude API key is not configured")
        logger.info("Using Claude as the LLM provider")
        return LLMAPI(config.claude_api_key)
    
    else:
        raise ValueError(f"Unknown LLM provider: {provider}")