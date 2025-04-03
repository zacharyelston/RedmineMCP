#!/usr/bin/env python3
"""
Utility functions for Redmine API interaction.
This module provides common functions used by the Redmine scripts.
"""

import os
import json
import yaml
import sys
import requests
from urllib.parse import urljoin

def load_config():
    """Load Redmine API configuration from credentials.yaml"""
    config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'credentials.yaml')
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
            return config
    except Exception as e:
        print(f"Error loading configuration: {str(e)}")
        sys.exit(1)

def load_template(template_name):
    """Load YAML template file for Redmine API operation"""
    template_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 
                                'templates', f"{template_name}.yaml")
    try:
        with open(template_path, 'r') as file:
            template = yaml.safe_load(file)
            return template
    except Exception as e:
        print(f"Error loading template {template_name}: {str(e)}")
        sys.exit(1)

def make_request(method, endpoint, data=None, params=None, files=None):
    """Make a request to the Redmine API"""
    config = load_config()
    redmine_url = config.get('redmine_url')
    redmine_api_key = config.get('redmine_api_key')
    
    if not redmine_url or not redmine_api_key:
        print("Missing Redmine URL or API key in configuration")
        sys.exit(1)
    
    # Ensure URL ends with a trailing slash
    if not redmine_url.endswith('/'):
        redmine_url = redmine_url + '/'
    
    url = urljoin(redmine_url, endpoint)
    
    headers = {
        "Content-Type": "application/json",
        "X-Redmine-API-Key": redmine_api_key
    }
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, params=params)
        elif method == 'POST':
            if files:
                # For file uploads, don't send JSON
                headers_without_content_type = {k: v for k, v in headers.items() if k != 'Content-Type'}
                response = requests.post(url, headers=headers_without_content_type, data=data, files=files)
            else:
                response = requests.post(url, headers=headers, json=data)
        elif method == 'PUT':
            response = requests.put(url, headers=headers, json=data)
        elif method == 'DELETE':
            response = requests.delete(url, headers=headers)
        else:
            print(f"Unsupported HTTP method: {method}")
            sys.exit(1)
        
        if response.status_code >= 400:
            print(f"API request failed with status code {response.status_code}: {response.text}")
            sys.exit(1)
        
        # For successful requests with no content
        if response.status_code == 204 or not response.text.strip():
            return {"success": True, "message": "Operation completed successfully"}
        
        return response.json()
    
    except requests.exceptions.RequestException as e:
        print(f"Failed to communicate with Redmine API: {str(e)}")
        sys.exit(1)

def save_response(response, output_file=None):
    """Save API response to file or print to stdout"""
    if output_file:
        try:
            with open(output_file, 'w') as file:
                json.dump(response, file, indent=2)
            print(f"Response saved to {output_file}")
        except Exception as e:
            print(f"Error saving response to file: {str(e)}")
            print(json.dumps(response, indent=2))
    else:
        print(json.dumps(response, indent=2))
