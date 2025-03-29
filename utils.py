"""
Utility functions for the Redmine MCP Extension.
Uses file-based configuration instead of database.
"""

import os
import yaml
import logging
import requests
from datetime import datetime

logger = logging.getLogger(__name__)

# Import rate limiting functions from config module
from config import is_rate_limited as config_is_rate_limited
from config import add_api_call as config_add_api_call

def is_rate_limited(api_name, rate_limit_per_minute):
    """
    Check if the API has exceeded its rate limit
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
        rate_limit_per_minute (int): The maximum number of calls allowed per minute
        
    Returns:
        bool: True if rate limited, False otherwise
    """
    return config_is_rate_limited(api_name)

def add_api_call(api_name):
    """
    Increment the API call counter for rate limiting
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
    """
    config_add_api_call(api_name)

# Import functions from config module
from config import load_credentials as config_load_credentials
from config import update_config_from_credentials as config_update_from_credentials

def load_credentials():
    """
    Load credentials from credentials.yaml file
    
    Returns:
        dict: The loaded credentials or None if file not found
    """
    return config_load_credentials()

def update_config_from_credentials():
    """
    Updates the application configuration from credentials.yaml file
    
    Returns:
        tuple: (bool, str) - Success status and message
    """
    return config_update_from_credentials()

def check_redmine_availability(url, timeout=5):
    """
    Check if Redmine is available at the specified URL
    
    Args:
        url (str): The Redmine URL to check
        timeout (int, optional): Timeout in seconds
        
    Returns:
        tuple: (bool, str) - Available status and message
    """
    try:
        # Strip API endpoint parts if present
        base_url = url.split('/api/')[0]
        base_url = base_url.rstrip('/')
        
        # Make a request to the Redmine root
        response = requests.get(f"{base_url}", timeout=timeout)
        
        if response.status_code == 200:
            logger.info(f"Redmine is available at {base_url}")
            return True, "Redmine is available"
        else:
            logger.warning(f"Redmine returned unexpected status code: {response.status_code}")
            return False, f"Redmine returned status code {response.status_code}"
    except requests.exceptions.ConnectionError:
        logger.warning(f"Could not connect to Redmine at {url}")
        return False, "Could not connect to Redmine (connection error)"
    except requests.exceptions.Timeout:
        logger.warning(f"Connection to Redmine timed out after {timeout} seconds")
        return False, "Connection to Redmine timed out"
    except Exception as e:
        logger.error(f"Error checking Redmine availability: {str(e)}")
        return False, f"Error checking Redmine availability: {str(e)}"

def create_credentials_file(redmine_url, redmine_api_key, mcp_url=None, 
                       rate_limit_per_minute=60):
    """
    Creates a credentials.yaml file with the provided settings
    
    Args:
        redmine_url (str): The Redmine instance URL
        redmine_api_key (str): The Redmine API key
        mcp_url (str, optional): The MCP service URL
        rate_limit_per_minute (int, optional): Rate limit for API calls
        
    Returns:
        tuple: (bool, str) - Success status and message
    """
    try:
        # Create the credentials dictionary
        credentials = {
            'redmine_url': redmine_url,
            'redmine_api_key': redmine_api_key,
            'llm_provider': 'claude-desktop',
            'rate_limit_per_minute': rate_limit_per_minute
        }
        
        # Add MCP URL if provided
        if mcp_url:
            credentials['mcp_url'] = mcp_url
        else:
            # Default to port 9000
            credentials['mcp_url'] = 'http://localhost:9000'
        
        # Save to the file
        with open('credentials.yaml', 'w') as file:
            yaml.dump(credentials, file, default_flow_style=False)
        
        # Also create an example file if it doesn't exist
        if not os.path.exists('credentials.yaml.example'):
            with open('credentials.yaml.example', 'w') as file:
                example = {
                    'redmine_url': 'https://redmine.example.com',
                    'redmine_api_key': 'your_redmine_api_key_here',
                    'llm_provider': 'claude-desktop',
                    'mcp_url': 'http://localhost:9000',
                    'rate_limit_per_minute': 60
                }
                yaml.dump(example, file, default_flow_style=False)
        
        # Reset the config to force reload in the config module
        import config
        if hasattr(config, '_config'):
            config._config = None
        
        logger.info("Credentials file created successfully")
        return True, "Credentials file created successfully"
    
    except Exception as e:
        logger.error(f"Error creating credentials file: {str(e)}")
        return False, f"Error creating credentials file: {str(e)}"