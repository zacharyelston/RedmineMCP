#!/usr/bin/env python3
"""
Fix Redmine Trackers Script

This script explicitly fixes the 403 Forbidden error when creating trackers in Redmine.
It uses both API key authentication and basic authentication to ensure admin privileges.

Usage:
    python scripts/fix_redmine_trackers.py [--config /path/to/credentials.yaml] [--redmine-url URL] [--admin-username USERNAME] [--admin-password PASSWORD]
"""

import argparse
import json
import logging
import os
import sys
import time
import yaml
import requests
from requests.auth import HTTPBasicAuth

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Default trackers to create if they don't exist
DEFAULT_TRACKERS = [
    {"name": "Bug", "description": "Software defects and issues", "default_status_id": 1},
    {"name": "Feature", "description": "New features and enhancements", "default_status_id": 1},
    {"name": "Support", "description": "Support requests and questions", "default_status_id": 1}
]


def load_config(config_path=None):
    """
    Load configuration from the credentials.yaml file.
    
    Args:
        config_path (str): Optional path to credentials file. If not provided,
                         will look in project root.
    
    Returns:
        dict: Configuration dictionary
    """
    if not config_path:
        # Try to find the credentials file in the project root
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        config_path = os.path.join(project_root, 'credentials.yaml')
    
    logger.info(f"Loading configuration from {config_path}")
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
        return config
    except FileNotFoundError:
        logger.error(f"Configuration file not found at {config_path}")
        sys.exit(1)
    except yaml.YAMLError as e:
        logger.error(f"Error parsing YAML configuration: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error loading config: {e}")
        sys.exit(1)


def authenticate_and_verify(redmine_url, api_key, username, password):
    """
    Authenticate with Redmine using both API key and Basic auth to verify admin access
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        username (str): Admin username
        password (str): Admin password
    
    Returns:
        bool: True if authentication successful and user is admin
    """
    # First check with API key
    headers = {
        "Content-Type": "application/json",
        "X-Redmine-API-Key": api_key
    }
    
    try:
        response = requests.get(f"{redmine_url}/users/current.json", headers=headers, timeout=10)
        response.raise_for_status()
        user_data = response.json().get('user', {})
        logger.info(f"API Key Authentication: Successfully connected as {user_data.get('login')} (Admin: {user_data.get('admin', False)})")
        
        # If not admin, try basic auth
        if not user_data.get('admin', False):
            logger.warning("API key user does not have admin privileges. Trying basic auth...")
            auth = HTTPBasicAuth(username, password)
            response = requests.get(f"{redmine_url}/users/current.json", auth=auth, timeout=10)
            response.raise_for_status()
            user_data = response.json().get('user', {})
            logger.info(f"Basic Auth: Successfully connected as {user_data.get('login')} (Admin: {user_data.get('admin', False)})")
            
            if not user_data.get('admin', False):
                logger.error("Neither API key nor provided username/password has admin privileges.")
                return False
        
        return True
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        return False


def create_trackers(redmine_url, api_key, username, password):
    """
    Create the default trackers in Redmine using both authentication methods
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        username (str): Admin username
        password (str): Admin password
    
    Returns:
        bool: True if successful
    """
    # First try with API key
    success_with_api_key = try_create_trackers(redmine_url, api_key=api_key)
    
    # If that fails, try with basic auth
    if not success_with_api_key:
        logger.warning("Failed to create trackers with API key. Trying basic auth...")
        success_with_basic_auth = try_create_trackers(redmine_url, username=username, password=password)
        return success_with_basic_auth
    
    return success_with_api_key


def try_create_trackers(redmine_url, api_key=None, username=None, password=None):
    """
    Try to create trackers with either API key or basic auth
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str, optional): Redmine API key
        username (str, optional): Admin username
        password (str, optional): Admin password
    
    Returns:
        bool: True if at least one tracker created successfully
    """
    headers = {"Content-Type": "application/json"}
    auth = None
    
    if api_key:
        headers["X-Redmine-API-Key"] = api_key
    elif username and password:
        auth = HTTPBasicAuth(username, password)
    else:
        logger.error("No authentication provided")
        return False
        
    # First get existing trackers
    try:
        if auth:
            response = requests.get(f"{redmine_url}/trackers.json", headers=headers, auth=auth, timeout=10)
        else:
            response = requests.get(f"{redmine_url}/trackers.json", headers=headers, timeout=10)
            
        response.raise_for_status()
        existing_trackers = response.json().get('trackers', [])
        existing_tracker_names = [t['name'] for t in existing_trackers]
        logger.info(f"Found {len(existing_trackers)} existing trackers: {', '.join(existing_tracker_names) if existing_trackers else 'None'}")
    except Exception as e:
        logger.error(f"Error retrieving existing trackers: {e}")
        return False
    
    # Create missing trackers
    success_count = 0
    for tracker in DEFAULT_TRACKERS:
        if tracker['name'] in existing_tracker_names:
            logger.info(f"✅ Tracker already exists: {tracker['name']}")
            success_count += 1
            continue
            
        logger.info(f"Creating tracker: {tracker['name']}")
        data = {"tracker": tracker}
        
        try:
            if auth:
                response = requests.post(
                    f"{redmine_url}/trackers.json", 
                    headers=headers,
                    auth=auth, 
                    json=data,
                    timeout=10
                )
            else:
                response = requests.post(
                    f"{redmine_url}/trackers.json", 
                    headers=headers,
                    json=data,
                    timeout=10
                )
                
            response.raise_for_status()
            logger.info(f"✅ Created tracker: {tracker['name']}")
            success_count += 1
        except Exception as e:
            logger.error(f"Error creating tracker {tracker['name']}: {e}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"Response: {e.response.text}")
    
    return success_count > 0


def main():
    parser = argparse.ArgumentParser(description='Fix Redmine Trackers')
    parser.add_argument('--config', help='Path to credentials.yaml file')
    parser.add_argument('--redmine-url', help='URL of the Redmine server')
    parser.add_argument('--admin-username', default='admin', help='Admin username for Redmine')
    parser.add_argument('--admin-password', default='admin', help='Admin password for Redmine')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Load configuration
    config = load_config(args.config)
    redmine_url = args.redmine_url or config.get('redmine_url', '').rstrip('/')
    api_key = config.get('redmine_api_key', '')
    admin_username = args.admin_username
    admin_password = args.admin_password
    
    if not redmine_url:
        logger.error("Redmine URL not specified")
        sys.exit(1)
    
    if not api_key:
        logger.error("API key not found in configuration")
        sys.exit(1)
    
    logger.info(f"Fixing Redmine trackers at {redmine_url}")
    
    # Authenticate and verify admin access
    if not authenticate_and_verify(redmine_url, api_key, admin_username, admin_password):
        logger.error("Failed to authenticate with admin privileges")
        sys.exit(1)
    
    # Create missing trackers
    if create_trackers(redmine_url, api_key, admin_username, admin_password):
        logger.info("✅ Successfully created missing trackers!")
    else:
        logger.error("❌ Failed to create trackers")
        sys.exit(1)
    
    # Verify trackers were created
    try:
        headers = {"Content-Type": "application/json", "X-Redmine-API-Key": api_key}
        response = requests.get(f"{redmine_url}/trackers.json", headers=headers, timeout=10)
        trackers = response.json().get('trackers', [])
        logger.info(f"Final tracker count: {len(trackers)}")
        tracker_names = [t['name'] for t in trackers]
        logger.info(f"Available trackers: {', '.join(tracker_names)}")
        
        # Check if all default trackers exist
        missing = [t['name'] for t in DEFAULT_TRACKERS if t['name'] not in tracker_names]
        if missing:
            logger.warning(f"Still missing trackers: {', '.join(missing)}")
        else:
            logger.info("✅ All default trackers are now available!")
    except Exception as e:
        logger.error(f"Error verifying trackers: {e}")
    
    logger.info("Fix completed!")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("\nProcess interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)
