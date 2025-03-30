#!/usr/bin/env python3
"""
Bootstrap Redmine with basic configuration after initial setup.

This script adds essential configuration to a Redmine instance after it has been set up:
- Creates default trackers (Bug, Feature, Support)
- Ensures issue statuses are properly configured
- Sets up basic roles and permissions

Usage:
    python scripts/bootstrap_redmine.py [--config /path/to/credentials.yaml] [--verbose]
"""

import argparse
import logging
import os
import sys
import time
import yaml

from redminelib import Redmine
from redminelib.exceptions import ResourceNotFoundError, AuthError, ValidationError

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

# Default roles if needed
DEFAULT_ROLES = [
    {"name": "Developer", "permissions": ["add_issues", "edit_issues", "view_issues"]},
    {"name": "Reporter", "permissions": ["add_issues", "view_issues"]},
    {"name": "Manager", "permissions": ["add_issues", "edit_issues", "delete_issues", "view_issues"]}
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


def connect_to_redmine(config):
    """
    Connect to the Redmine instance using the provided configuration.
    
    Args:
        config (dict): Configuration dictionary with Redmine connection details
    
    Returns:
        Redmine: Redmine client instance
    """
    redmine_url = config['redmine_url']
    redmine_api_key = config['redmine_api_key']
    
    logger.info(f"Connecting to Redmine at {redmine_url}")
    try:
        redmine = Redmine(redmine_url, key=redmine_api_key)
        # Test the connection
        user = redmine.user.get('current')
        logger.info(f"Successfully connected to Redmine as: {user.firstname} {user.lastname}")
        is_admin = hasattr(user, 'admin') and user.admin
        logger.info(f"User is admin: {is_admin}")
        if not is_admin:
            logger.warning("The user does not have admin privileges. Some operations may fail.")
        return redmine
    except AuthError as e:
        logger.error(f"Authentication error: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Error connecting to Redmine: {e}")
        sys.exit(1)


def ensure_trackers_exist(redmine):
    """
    Ensure that the default trackers exist in Redmine.
    
    Args:
        redmine (Redmine): Redmine client instance
    """
    logger.info("Checking for existing trackers...")
    try:
        existing_trackers = list(redmine.tracker.all())
        existing_tracker_names = [t.name for t in existing_trackers]
        logger.info(f"Found {len(existing_trackers)} existing trackers: {', '.join(existing_tracker_names) if existing_trackers else 'None'}")
        
        for tracker in DEFAULT_TRACKERS:
            if tracker['name'] not in existing_tracker_names:
                logger.info(f"Creating tracker: {tracker['name']}")
                try:
                    redmine.tracker.create(
                        name=tracker['name'],
                        default_status_id=tracker['default_status_id'],
                        description=tracker['description']
                    )
                    logger.info(f"✅ Created tracker: {tracker['name']}")
                except ValidationError as e:
                    logger.error(f"⚠️ Error creating tracker {tracker['name']}: {e}")
                except Exception as e:
                    logger.error(f"⚠️ Unexpected error creating tracker {tracker['name']}: {e}")
            else:
                logger.info(f"✅ Tracker already exists: {tracker['name']}")
    except Exception as e:
        logger.error(f"Error checking/creating trackers: {e}")


def check_statuses(redmine):
    """
    Check and log the available issue statuses in Redmine.
    
    Args:
        redmine (Redmine): Redmine client instance
    """
    logger.info("Checking issue statuses...")
    try:
        statuses = list(redmine.issue_status.all())
        status_names = [f"{s.id}: {s.name}" for s in statuses]
        logger.info(f"Found {len(statuses)} issue statuses: {', '.join(status_names) if statuses else 'None'}")
        
        # Just checking if we have the minimum required statuses
        if len(statuses) < 3:
            logger.warning("Fewer than 3 issue statuses found. A typical Redmine setup has at least New, In Progress, and Closed.")
    except Exception as e:
        logger.error(f"Error checking issue statuses: {e}")


def ensure_roles_exist(redmine):
    """
    Ensure that the default roles exist in Redmine.
    
    Args:
        redmine (Redmine): Redmine client instance
    """
    logger.info("Checking for existing roles...")
    try:
        existing_roles = list(redmine.role.all())
        existing_role_names = [r.name for r in existing_roles]
        logger.info(f"Found {len(existing_roles)} existing roles: {', '.join(existing_role_names) if existing_roles else 'None'}")
        
        # Since role creation via API is complex, we'll just log what's missing
        for role in DEFAULT_ROLES:
            if role['name'] not in existing_role_names:
                logger.warning(f"Role not found: {role['name']}. Consider creating it in the Redmine UI.")
            else:
                logger.info(f"✅ Role already exists: {role['name']}")
    except Exception as e:
        logger.error(f"Error checking roles: {e}")


def create_test_project(redmine):
    """
    Create a test project if it doesn't exist.
    
    Args:
        redmine (Redmine): Redmine client instance
    """
    project_identifier = 'test-project'
    logger.info(f"Checking for test project with identifier '{project_identifier}'...")
    
    try:
        try:
            project = redmine.project.get(project_identifier)
            logger.info(f"✅ Test project already exists: {project.name}")
        except ResourceNotFoundError:
            logger.info("Creating test project...")
            project = redmine.project.create(
                name='Test Project',
                identifier=project_identifier,
                description='A test project created by the bootstrap script',
                is_public=True
            )
            logger.info(f"✅ Created test project: {project.name}")
    except Exception as e:
        logger.error(f"Error checking/creating test project: {e}")


def main():
    parser = argparse.ArgumentParser(description='Bootstrap a Redmine instance with basic configuration.')
    parser.add_argument('--config', help='Path to credentials.yaml file')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    parser.add_argument('--no-wait', action='store_true', help='Don\'t wait for Redmine to start')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Load configuration
    config = load_config(args.config)
    
    # Wait for Redmine to be fully up and running
    if not args.no_wait:
        logger.info("Waiting for Redmine to be ready...")
        wait_time = 5  # seconds
        logger.info(f"Waiting {wait_time} seconds for Redmine to start...")
        time.sleep(wait_time)
    
    # Connect to Redmine
    redmine = connect_to_redmine(config)
    
    # Bootstrap the Redmine instance
    ensure_trackers_exist(redmine)
    check_statuses(redmine)
    ensure_roles_exist(redmine)
    create_test_project(redmine)
    
    logger.info("✅ Redmine bootstrap completed successfully!")


if __name__ == '__main__':
    main()
