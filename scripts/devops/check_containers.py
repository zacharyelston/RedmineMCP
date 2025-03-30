#!/usr/bin/env python3
"""
Simple script to check if Redmine and MCP containers are running and accessible.
"""

import requests
import sys
import logging
import json
import os
import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def load_config():
    """Load configuration from the credentials file"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    config_path = os.path.join(project_root, 'credentials.yaml')
    
    try:
        with open(config_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        return {}

def check_redmine_status