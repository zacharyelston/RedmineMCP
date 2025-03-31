#!/usr/bin/env python3
"""
Script to create a new project in Redmine for RedmineMCP
"""

import json
import logging
import requests
import sys
from urllib.parse import urljoin

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def create_project(base_url, api_key, name, identifier, description, is_public=True):
    """
    Create a new project in Redmine
    """
    url = urljoin(base_url, 'projects.json')
    headers = {
        "Content-Type": "application/json",
        "X-Redmine-API-Key": api_key
    }
    data = {
        "project": {
            "name": name,
            "identifier": identifier,
            "description": description,
            "is_public": is_public
        }
    }
    
    logger.debug(f"Creating project with URL: {url}")
    logger.debug(f"Headers: {headers}")
    logger.debug(f"Data: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(url, headers=headers, json=data)
        logger.debug(f"Response status: {response.status_code}")
        logger.debug(f"Response body: {response.text}")
        
        response.raise_for_status()  # Raise an exception for 4XX/5XX responses
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        return {"error": str(e)}

if __name__ == "__main__":
    # Configuration
    api_key = "cb2915c1c6f54ae974321dc42525f4c346f13fb0"
    redmine_url = "http://localhost:3000/"
    
    # Project details
    project_name = "RedmineMCP Extension"
    project_identifier = "redmine-mcp"
    project_description = "A Model Context Protocol (MCP) extension for Redmine that leverages LLMs to streamline issue management."
    
    # Create the project
    result = create_project(redmine_url, api_key, project_name, project_identifier, project_description)
    
    # Print result
    if "error" in result:
        logger.error(f"Failed to create project: {result['error']}")
        sys.exit(1)
    else:
        logger.info(f"Project created successfully: {json.dumps(result, indent=2)}")
        sys.exit(0)
