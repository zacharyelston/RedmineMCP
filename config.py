"""
Configuration management for the Redmine MCP Extension.
Replaces database configuration with file-based configuration.
"""
import os
import yaml
import logging
import time
from datetime import datetime, timedelta
from collections import defaultdict

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Global configuration
_config = None
_manifest = None
_rate_limit_counters = defaultdict(int)
_rate_limit_reset_times = defaultdict(lambda: datetime.utcnow())
_action_log_file = os.path.join('logs', 'actions.log')

def load_yaml_file(file_path):
    """
    Load a YAML file
    
    Args:
        file_path (str): Path to the YAML file
        
    Returns:
        dict: The loaded YAML data or None if file not found
    """
    try:
        if os.path.exists(file_path):
            with open(file_path, 'r') as file:
                return yaml.safe_load(file)
        else:
            logger.warning(f"YAML file not found: {file_path}")
            return None
    except Exception as e:
        logger.error(f"Error loading YAML file: {str(e)}")
        return None

def load_credentials():
    """
    Load credentials from credentials.yaml file
    
    Returns:
        dict: The loaded credentials or None if file not found
    """
    return load_yaml_file('credentials.yaml')

def load_manifest():
    """
    Load manifest from manifest.yaml file
    
    Returns:
        dict: The loaded manifest or None if file not found
    """
    return load_yaml_file('manifest.yaml')

def get_config():
    """
    Get the current configuration
    
    Returns:
        dict: The current configuration
    """
    global _config
    
    if _config is None:
        _config = {}
        credentials = load_credentials()
        
        if credentials:
            # Copy credentials into config
            _config['redmine_url'] = credentials.get('redmine_url')
            _config['redmine_api_key'] = credentials.get('redmine_api_key')
            
            # Get MCP URL
            _config['mcp_url'] = credentials.get('mcp_url')
                
            # If MCP URL is missing, set a default port 9000
            if not _config['mcp_url']:
                _config['mcp_url'] = 'http://localhost:9000'
                logger.info(f"Using default MCP URL: {_config['mcp_url']}")
                
            # Kept for backward compatibility
            _config['claude_api_key'] = credentials.get('claude_api_key')
            _config['llm_provider'] = credentials.get('llm_provider', 'claude-desktop')
                
            # Ensure provider is 'claude-desktop'
            if _config['llm_provider'] != 'claude-desktop':
                logger.warning("Using 'claude-desktop' as the LLM provider.")
                _config['llm_provider'] = 'claude-desktop'
    
    return _config

def get_manifest():
    """
    Get the current manifest
    
    Returns:
        dict: The current manifest
    """
    global _manifest
    
    if _manifest is None:
        _manifest = load_manifest() or {}
        
    return _manifest

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
        
        # Validate the required credentials
        if not redmine_url or not redmine_api_key:
            return False, "Required Redmine credentials are missing"
        
        # Reset the config to force reload
        global _config
        _config = None
        
        return True, "Configuration updated successfully"
    
    except Exception as e:
        logger.error(f"Error updating configuration: {str(e)}")
        return False, f"Error updating configuration: {str(e)}"

def get_prompt_template(template_name):
    """
    Get a prompt template by name
    
    Args:
        template_name (str): The name of the template
        
    Returns:
        dict: The prompt template or None if not found
    """
    manifest = get_manifest()
    templates = manifest.get('prompt_templates', {})
    
    return templates.get(template_name)

def get_rate_limit():
    """
    Get the current rate limit per minute
    
    Returns:
        int: The rate limit per minute
    """
    manifest = get_manifest()
    return manifest.get('rate_limit_per_minute', 60)

def is_rate_limited(api_name):
    """
    Check if the API has exceeded its rate limit
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
        
    Returns:
        bool: True if rate limited, False otherwise
    """
    global _rate_limit_counters, _rate_limit_reset_times
    
    rate_limit = get_rate_limit()
    now = datetime.utcnow()
    reset_time = _rate_limit_reset_times[api_name]
    
    # Reset counter if the minute has passed
    if now >= reset_time:
        _rate_limit_counters[api_name] = 0
        _rate_limit_reset_times[api_name] = now + timedelta(minutes=1)
    
    # Check if rate limited
    return _rate_limit_counters[api_name] >= rate_limit

def add_api_call(api_name):
    """
    Increment the API call counter for rate limiting
    
    Args:
        api_name (str): The name of the API ('redmine' or 'claude')
    """
    global _rate_limit_counters
    
    # Increment counter
    _rate_limit_counters[api_name] += 1
    
    logger.debug(f"API call counter for {api_name}: {_rate_limit_counters[api_name]}")

def log_action(action_type, issue_id, content, prompt, response, success=True, error_message=None):
    """
    Log an action to the actions log file
    
    Args:
        action_type (str): The type of action (create, update, etc.)
        issue_id (int): The ID of the issue (or None)
        content (str): What was done
        prompt (str): The prompt that was sent to the LLM
        response (str): The response from the LLM
        success (bool): Whether the action was successful
        error_message (str): Error message if action failed
    """
    try:
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'action_type': action_type,
            'issue_id': issue_id,
            'content': content,
            'prompt': prompt,
            'response': response,
            'success': success,
            'error_message': error_message
        }
        
        with open(_action_log_file, 'a') as f:
            f.write(yaml.dump([log_entry], default_flow_style=False))
            f.write('---\n')
            
        logger.debug(f"Action logged: {action_type} for issue {issue_id}")
    except Exception as e:
        logger.error(f"Error logging action: {str(e)}")

def get_action_logs(limit=25):
    """
    Get the most recent action logs
    
    Args:
        limit (int): Maximum number of logs to return
        
    Returns:
        list: List of action log entries
    """
    try:
        if not os.path.exists(_action_log_file):
            return []
            
        with open(_action_log_file, 'r') as f:
            content = f.read()
            
        # Split by YAML document separator
        documents = content.split('---\n')
        
        logs = []
        for doc in documents:
            if doc.strip():
                try:
                    log_entries = yaml.safe_load(doc)
                    if isinstance(log_entries, list):
                        logs.extend(log_entries)
                    else:
                        logs.append(log_entries)
                except Exception as e:
                    logger.error(f"Error parsing log entry: {str(e)}")
        
        # Sort by timestamp (newest first)
        logs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        # Limit the number of logs
        return logs[:limit]
    except Exception as e:
        logger.error(f"Error getting action logs: {str(e)}")
        return []