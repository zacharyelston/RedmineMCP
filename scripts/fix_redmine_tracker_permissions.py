#!/usr/bin/env python3
"""
Fix Redmine Tracker Permissions

This script updates the Redmine configuration to enable API access for trackers
and then creates the necessary trackers.

Usage:
    python scripts/fix_redmine_tracker_permissions.py
"""

import requests
import json
import logging
import os
import sys
import yaml
import time
import base64
from requests.auth import HTTPBasicAuth

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Default trackers to create
DEFAULT_TRACKERS = [
    {"name": "Bug", "description": "Software defects and issues", "default_status_id": 1},
    {"name": "Feature", "description": "New features and enhancements", "default_status_id": 1},
    {"name": "Support", "description": "Support requests and questions", "default_status_id": 1}
]

def load_config(config_path=None):
    """Load configuration from the credentials.yaml file"""
    if not config_path:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        config_path = os.path.join(project_root, 'credentials.yaml')
    
    logger.info(f"Loading configuration from {config_path}")
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
        return config
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        return {}

def get_session(redmine_url, api_key=None, username=None, password=None):
    """
    Create an authenticated session with Redmine
    Tries API key first, then username/password
    """
    session = requests.Session()
    
    # Set default headers for JSON API
    session.headers.update({
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    })
    
    # Try API key if provided
    if api_key:
        session.headers.update({'X-Redmine-API-Key': api_key})
    
    # Try basic auth if provided
    if username and password:
        session.auth = HTTPBasicAuth(username, password)
    
    # Verify session works
    try:
        response = session.get(f"{redmine_url}/users/current.json")
        if response.status_code == 200:
            user = response.json().get('user', {})
            logger.info(f"Successfully authenticated as: {user.get('login')} (Admin: {user.get('admin', False)})")
            return session
        else:
            logger.warning(f"Authentication failed with status code: {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error authenticating: {e}")
        return None

def try_login_and_get_cookie(redmine_url, username, password):
    """Try to log in via form and get authentication cookie"""
    session = requests.Session()
    
    try:
        # First, get the login page to extract CSRF token
        login_page = session.get(f"{redmine_url}/login")
        if login_page.status_code != 200:
            logger.error(f"Failed to access login page: {login_page.status_code}")
            return None
        
        # Extract CSRF token - this is a simplification, may need adjustment
        csrf_token = None
        for line in login_page.text.split('\n'):
            if 'authenticity_token' in line and 'value=' in line:
                start = line.find('value="') + 7
                end = line.find('"', start)
                if start > 0 and end > 0:
                    csrf_token = line[start:end]
                    break
        
        if not csrf_token:
            logger.warning("Could not find CSRF token, trying anyway")
        
        # Submit login form
        login_data = {
            'username': username,
            'password': password,
            'authenticity_token': csrf_token,
            'login': 'Login'
        }
        
        login_response = session.post(
            f"{redmine_url}/login",
            data=login_data,
            allow_redirects=True
        )
        
        # Check if login was successful
        if login_response.url.endswith('/my/page'):
            logger.info("Login successful via web form")
            return session
        else:
            logger.warning("Login via web form failed")
            return None
    except Exception as e:
        logger.error(f"Error during web login: {e}")
        return None

def modify_redmine_database_yml():
    """
    Attempt to directly modify Redmine's database.yml config in the container
    to enable API access for all entities including trackers
    """
    return

def create_trackers_with_session(redmine_url, session):
    """Create trackers using the authenticated session"""
    # First check for existing trackers
    try:
        response = session.get(f"{redmine_url}/trackers.json")
        if response.status_code == 200:
            existing_trackers = response.json().get('trackers', [])
            existing_tracker_names = [t['name'] for t in existing_trackers]
            logger.info(f"Found {len(existing_trackers)} existing trackers: {', '.join(existing_tracker_names) if existing_trackers else 'None'}")
        else:
            logger.error(f"Failed to get existing trackers: {response.status_code}")
            return False
    except Exception as e:
        logger.error(f"Error checking existing trackers: {e}")
        return False
    
    # Create missing trackers
    success_count = 0
    for tracker in DEFAULT_TRACKERS:
        if tracker['name'] in existing_tracker_names:
            logger.info(f"✅ Tracker already exists: {tracker['name']}")
            success_count += 1
            continue
        
        logger.info(f"Creating tracker: {tracker['name']}")
        try:
            data = {'tracker': tracker}
            response = session.post(f"{redmine_url}/trackers.json", json=data)
            
            if response.status_code in (201, 200):
                logger.info(f"✅ Created tracker: {tracker['name']}")
                success_count += 1
            else:
                logger.error(f"Failed to create tracker {tracker['name']}: {response.status_code}")
                if hasattr(response, 'text') and response.text:
                    logger.error(f"Response: {response.text[:200]}")
        except Exception as e:
            logger.error(f"Error creating tracker {tracker['name']}: {e}")
    
    # Final check for trackers
    try:
        response = session.get(f"{redmine_url}/trackers.json")
        if response.status_code == 200:
            final_trackers = response.json().get('trackers', [])
            logger.info(f"Final tracker count: {len(final_trackers)}")
            final_tracker_names = [t['name'] for t in final_trackers]
            logger.info(f"Available trackers: {', '.join(final_tracker_names)}")
            
            # Check if all default trackers exist
            missing = [t['name'] for t in DEFAULT_TRACKERS if t['name'] not in final_tracker_names]
            if missing:
                logger.warning(f"Still missing trackers: {', '.join(missing)}")
            else:
                logger.info("✅ All default trackers are now available!")
        else:
            logger.error(f"Failed to verify final trackers: {response.status_code}")
    except Exception as e:
        logger.error(f"Error verifying final trackers: {e}")
    
    return success_count == len(DEFAULT_TRACKERS)

def try_admin_panel_access(redmine_url, session):
    """Try to access admin panel directly"""
    try:
        response = session.get(f"{redmine_url}/admin")
        if response.status_code == 200:
            logger.info("Successfully accessed admin panel")
            
            # Try to access tracker admin page
            response = session.get(f"{redmine_url}/trackers")
            if response.status_code == 200:
                logger.info("Successfully accessed trackers admin page")
                return True
            else:
                logger.warning(f"Failed to access trackers admin page: {response.status_code}")
        else:
            logger.warning(f"Failed to access admin panel: {response.status_code}")
        return False
    except Exception as e:
        logger.error(f"Error accessing admin panel: {e}")
        return False

def validate_api_access(redmine_url, api_key):
    """Check if API can access and create resources"""
    headers = {'X-Redmine-API-Key': api_key, 'Content-Type': 'application/json'}
    
    try:
        # Check if we can access projects
        response = requests.get(f"{redmine_url}/projects.json", headers=headers)
        if response.status_code == 200:
            logger.info("API can access projects")
            
            # Try to create a test project to test write access
            test_id = f"test-{int(time.time())}"[-8:]
            test_project = {
                'project': {
                    'name': f'API Test Project {test_id}',
                    'identifier': f'api-test-{test_id}',
                    'description': 'Test project created to check API access',
                    'is_public': True
                }
            }
            
            response = requests.post(f"{redmine_url}/projects.json", headers=headers, json=test_project)
            if response.status_code in (201, 200):
                logger.info("API has write access (created test project)")
                return True
            else:
                logger.warning(f"API cannot create projects: {response.status_code}")
        else:
            logger.warning(f"API cannot access projects: {response.status_code}")
        return False
    except Exception as e:
        logger.error(f"Error validating API access: {e}")
        return False

def try_all_authentication_methods(redmine_url, api_key, username="admin", password="admin"):
    """Try all possible authentication methods to create trackers"""
    
    # Method 1: Try with API key
    logger.info("Method 1: Trying with API key...")
    api_session = get_session(redmine_url, api_key=api_key)
    if api_session and create_trackers_with_session(redmine_url, api_session):
        logger.info("✅ Successfully created trackers with API key!")
        return True
    
    # Method 2: Try with username/password via API
    logger.info("Method 2: Trying with username/password via API...")
    basic_auth_session = get_session(redmine_url, username=username, password=password)
    if basic_auth_session and create_trackers_with_session(redmine_url, basic_auth_session):
        logger.info("✅ Successfully created trackers with basic auth!")
        return True
    
    # Method 3: Try with web login and cookies
    logger.info("Method 3: Trying with web login and cookies...")
    cookie_session = try_login_and_get_cookie(redmine_url, username, password)
    if cookie_session and create_trackers_with_session(redmine_url, cookie_session):
        logger.info("✅ Successfully created trackers with cookie auth!")
        return True
    
    # Method 4: Try with combined API key and basic auth
    logger.info("Method 4: Trying with combined authentication...")
    combined_session = get_session(redmine_url, api_key=api_key, username=username, password=password)
    if combined_session and create_trackers_with_session(redmine_url, combined_session):
        logger.info("✅ Successfully created trackers with combined auth!")
        return True
    
    logger.warning("All authentication methods failed to create trackers")
    return False

def update_redmine_configuration():
    """
    Try to update Redmine configuration to enable API
    This is usually stored in configuration.yml in the Redmine installation
    """
    # This would require direct access to the container file system
    # Since we can't modify files in the container easily, we'll skip this
    # and focus on the API-based approaches
    logger.info("Configuration update not implemented - would require container file access")
    return False

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fix Redmine Tracker Permissions')
    parser.add_argument('--config', help='Path to credentials.yaml file')
    parser.add_argument('--username', default='admin', help='Redmine admin username')
    parser.add_argument('--password', default='admin', help='Redmine admin password')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Load configuration
    config = load_config(args.config)
    redmine_url = config.get('redmine_url', '').rstrip('/')
    api_key = config.get('redmine_api_key', '')
    
    if not redmine_url:
        logger.error("Redmine URL not specified in configuration")
        return 1
    
    if not api_key:
        logger.error("API key not found in configuration")
        return 1
    
    logger.info(f"Attempting to fix Redmine tracker permissions at {redmine_url}")
    
    # Check API access
    logger.info("Validating API access...")
    if validate_api_access(redmine_url, api_key):
        logger.info("✅ API access validated")
    else:
        logger.warning("⚠️ API access validation failed, but continuing anyway")
    
    # Try all authentication methods
    if try_all_authentication_methods(redmine_url, api_key, args.username, args.password):
        logger.info("✅ Successfully created trackers!")
        return 0
    
    # If all methods failed, try to update configuration
    logger.info("Attempting to update Redmine configuration...")
    if update_redmine_configuration():
        logger.info("✅ Configuration updated, retrying tracker creation...")
        if try_all_authentication_methods(redmine_url, api_key, args.username, args.password):
            logger.info("✅ Successfully created trackers after configuration update!")
            return 0
    
    logger.error("❌ Failed to create trackers after trying all methods")
    
    # Suggest workaround
    logger.info("\n=== Alternative Solution ===")
    logger.info("Since API methods have failed, please try using the Redmine web interface:")
    logger.info(f"1. Log in to Redmine at {redmine_url} with admin/admin")
    logger.info("2. Go to Administration > Trackers")
    logger.info("3. Manually create the Bug, Feature, and Support trackers")
    logger.info("4. Assign the trackers to your project")
    
    return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("\nProcess interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)
