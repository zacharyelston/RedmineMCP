#!/usr/bin/env python3
"""
Simplified bootstrap script for Redmine that uses direct HTTP requests instead of redminelib.
This script adds essential configuration to a Redmine instance after it has been set up.

Usage:
    python scripts/bootstrap_redmine_simple.py [--config /path/to/credentials.yaml]
"""

import argparse
import json
import logging
import os
import sys
import time
import yaml
import requests

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


def get_current_user(redmine_url, api_key):
    """
    Get current user information from Redmine API
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        
    Returns:
        dict: User information or None if failed
    """
    url = f"{redmine_url}/users/current.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json().get('user')
    except Exception as e:
        logger.error(f"Error getting current user: {e}")
        return None


def get_trackers(redmine_url, api_key):
    """
    Get existing trackers from Redmine API
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        
    Returns:
        list: List of trackers or None if failed
    """
    url = f"{redmine_url}/trackers.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json().get('trackers', [])
    except Exception as e:
        logger.error(f"Error getting trackers: {e}")
        return []


def create_tracker(redmine_url, api_key, tracker_data):
    """
    Create a new tracker in Redmine
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        tracker_data (dict): Tracker data
        
    Returns:
        bool: True if successful, False otherwise
    """
    url = f"{redmine_url}/trackers.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    data = {"tracker": tracker_data}
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=10)
        response.raise_for_status()
        logger.info(f"✅ Created tracker: {tracker_data['name']}")
        return True
    except Exception as e:
        logger.error(f"Error creating tracker {tracker_data['name']}: {e}")
        return False


def get_issue_statuses(redmine_url, api_key):
    """
    Get existing issue statuses from Redmine API
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        
    Returns:
        list: List of issue statuses or None if failed
    """
    url = f"{redmine_url}/issue_statuses.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json().get('issue_statuses', [])
    except Exception as e:
        logger.error(f"Error getting issue statuses: {e}")
        return []


def get_roles(redmine_url, api_key):
    """
    Get existing roles from Redmine API
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        
    Returns:
        list: List of roles or None if failed
    """
    url = f"{redmine_url}/roles.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json().get('roles', [])
    except Exception as e:
        logger.error(f"Error getting roles: {e}")
        return []


def create_test_project(redmine_url, api_key):
    """
    Create a test project in Redmine
    
    Args:
        redmine_url (str): Redmine URL
        api_key (str): Redmine API key
        
    Returns:
        dict: Project data or None if failed
    """
    url = f"{redmine_url}/projects.json"
    headers = {
        'X-Redmine-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    data = {
        "project": {
            "name": "Test Project",
            "identifier": "test-project",
            "description": "A test project created by the bootstrap script",
            "is_public": True,
            "enabled_module_names": [
                "issue_tracking", "time_tracking", "news", "documents", 
                "files", "wiki", "repository", "calendar", "gantt"
            ]
        }
    }
    
    # First check if project exists
    try:
        check_url = f"{redmine_url}/projects/test-project.json"
        check_response = requests.get(check_url, headers=headers, timeout=10)
        if check_response.status_code == 200:
            logger.info("✅ Test project already exists")
            return check_response.json().get('project')
    except:
        pass  # Project doesn't exist, continue to create it
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=10)
        response.raise_for_status()
        logger.info("✅ Created test project")
        return response.json().get('project')
    except Exception as e:
        logger.error(f"Error creating test project: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description='Bootstrap a Redmine instance with basic configuration.')
    parser.add_argument('--config', help='Path to credentials.yaml file')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    parser.add_argument('--no-wait', action='store_true', help="Don't wait for Redmine to start")
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Load configuration
    config = load_config(args.config)
    redmine_url = config.get('redmine_url', '').rstrip('/')
    api_key = config.get('redmine_api_key', '')
    
    if not redmine_url or not api_key:
        logger.error("Redmine URL and API key are required in the configuration")
        sys.exit(1)
    
    # Wait for Redmine to be fully up and running
    if not args.no_wait:
        logger.info("Waiting for Redmine to be ready...")
        wait_time = 5  # seconds
        logger.info(f"Waiting {wait_time} seconds for Redmine to start...")
        time.sleep(wait_time)
    
    # Test connection to Redmine
    user = get_current_user(redmine_url, api_key)
    if not user:
        logger.error("Failed to connect to Redmine, check URL and API key")
        sys.exit(1)
    
    logger.info(f"Connected to Redmine as: {user.get('login')} (Admin: {user.get('admin', False)})")
    
    # Check and create trackers
    trackers = get_trackers(redmine_url, api_key)
    logger.info(f"Found {len(trackers)} existing trackers")
    
    existing_tracker_names = [t['name'] for t in trackers]
    for tracker in DEFAULT_TRACKERS:
        if tracker['name'] not in existing_tracker_names:
            logger.info(f"Creating tracker: {tracker['name']}")
            create_tracker(redmine_url, api_key, tracker)
        else:
            logger.info(f"✅ Tracker already exists: {tracker['name']}")
    
    # Check issue statuses
    statuses = get_issue_statuses(redmine_url, api_key)
    status_names = [f"{s['id']}: {s['name']}" for s in statuses]
    logger.info(f"Found {len(statuses)} issue statuses: {', '.join(status_names) if statuses else 'None'}")
    
    # Check roles
    roles = get_roles(redmine_url, api_key)
    role_names = [r['name'] for r in roles]
    logger.info(f"Found {len(roles)} roles: {', '.join(role_names) if roles else 'None'}")
    
    # Create test project
    create_test_project(redmine_url, api_key)
    
    # Re-check trackers to confirm they were created
    final_trackers = get_trackers(redmine_url, api_key)
    logger.info(f"Final tracker count: {len(final_trackers)}")
    
    logger.info("✅ Redmine bootstrap completed successfully!")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        logger.info("\nBootstrap process interrupted by user")
        sys.exit(130)  # 130 is the standard exit code for SIGINT
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)
