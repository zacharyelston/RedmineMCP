"""
Utility functions for the Redmine MCP Extension.
"""

import os
import yaml
import logging
import requests
from datetime import datetime
from models import Config, RateLimitTracker, db

logger = logging.getLogger(__name__)

def is_rate_limited(api_name, rate_limit_per_minute):
    """
    Check if the API has exceeded its rate limit
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
        rate_limit_per_minute (int): The maximum number of calls allowed per minute
        
    Returns:
        bool: True if rate limited, False otherwise
    """
    # Get or create the tracker
    tracker = RateLimitTracker.get_or_create(api_name)
    
    # Check if we've exceeded the limit
    if tracker.count >= rate_limit_per_minute:
        logger.warning(f"{api_name} API rate limit exceeded. Count: {tracker.count}, Limit: {rate_limit_per_minute}")
        return True
    
    return False

def add_api_call(api_name):
    """
    Increment the API call counter for rate limiting
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
    """
    # Get or create the tracker
    tracker = RateLimitTracker.get_or_create(api_name)
    
    # Increment the counter
    tracker.count += 1
    db.session.commit()
    
    logger.debug(f"Recorded API call to {api_name}. New count: {tracker.count}")

def load_credentials():
    """
    Load credentials from credentials.yaml file
    
    Returns:
        dict: The loaded credentials or None if file not found
    """
    try:
        # Check if credentials.yaml exists
        if not os.path.exists('credentials.yaml'):
            logger.warning("credentials.yaml not found")
            return None
        
        # Load credentials from the file
        with open('credentials.yaml', 'r') as file:
            credentials = yaml.safe_load(file)
        
        logger.info("Credentials loaded from file")
        return credentials
    
    except Exception as e:
        logger.error(f"Error loading credentials: {str(e)}")
        return None

def update_config_from_credentials():
    """
    Updates the application configuration from credentials.yaml file
    
    Returns:
        tuple: (bool, str) - Success status and message
    """
    try:
        # Load credentials from file
        credentials = load_credentials()
        
        if not credentials:
            return False, "No credentials file found"
        
        # Get required fields
        redmine_url = credentials.get('redmine_url')
        redmine_api_key = credentials.get('redmine_api_key')
        mcp_url = credentials.get('mcp_url')
        claude_api_key = credentials.get('claude_api_key')  # Kept for backward compatibility
        llm_provider = credentials.get('llm_provider', 'claude-desktop')
        rate_limit = credentials.get('rate_limit_per_minute', 60)
        
        # Validate the required credentials
        if not redmine_url or not redmine_api_key:
            return False, "Required Redmine credentials are missing"
        
        # Claude API key is no longer required as we're using ClaudeDesktop MCP
            
        # Ensure provider is 'claude-desktop'
        if llm_provider != 'claude-desktop':
            logger.warning("Using 'claude-desktop' as the LLM provider.")
            llm_provider = 'claude-desktop'
        
        # Update or create configuration in the database
        config = Config.query.first()
        
        if config:
            # Update existing config
            config.redmine_url = redmine_url
            config.redmine_api_key = redmine_api_key
            config.mcp_url = mcp_url
            config.claude_api_key = claude_api_key  # For backward compatibility
            config.llm_provider = llm_provider
            config.rate_limit_per_minute = rate_limit
            config.updated_at = datetime.utcnow()
        else:
            # Create new config
            config = Config(
                redmine_url=redmine_url,
                redmine_api_key=redmine_api_key,
                mcp_url=mcp_url,
                claude_api_key=claude_api_key,  # For backward compatibility
                llm_provider=llm_provider,
                rate_limit_per_minute=rate_limit
            )
            db.session.add(config)
        
        db.session.commit()
        logger.info("Configuration updated from credentials file")
        return True, "Configuration updated successfully"
    
    except Exception as e:
        logger.error(f"Error updating configuration: {str(e)}")
        return False, f"Error updating configuration: {str(e)}"

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
            credentials['mcp_url'] = 'http://localhost:5001/api'
        
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
                    'mcp_url': 'http://localhost:5001/api',
                    'rate_limit_per_minute': 60
                }
                yaml.dump(example, file, default_flow_style=False)
        
        logger.info("Credentials file created successfully")
        return True, "Credentials file created successfully"
    
    except Exception as e:
        logger.error(f"Error creating credentials file: {str(e)}")
        return False, f"Error creating credentials file: {str(e)}"