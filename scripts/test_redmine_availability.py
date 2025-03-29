#!/usr/bin/env python3
"""
Test script to check how the MCP extension handles a missing or unavailable Redmine instance.
This is useful for testing the improved error handling and offline capabilities.
"""

import os
import sys
import json
import logging
import argparse
import requests
from datetime import datetime
import yaml

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Default MCP endpoint
DEFAULT_MCP_URL = "http://localhost:5000"

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test how MCP extension handles unavailable Redmine")
    parser.add_argument("--mcp-url", default=DEFAULT_MCP_URL, help="URL of the MCP extension service")
    parser.add_argument("--credentials", default="../credentials.yaml", help="Path to credentials.yaml file")
    parser.add_argument("--create-test-config", action="store_true", 
                        help="Create a test configuration with non-existent Redmine URL")
    parser.add_argument("--restore-config", action="store_true", 
                        help="Restore original configuration after testing")
    return parser.parse_args()

def load_credentials(file_path):
    """Load credentials from YAML file"""
    try:
        with open(file_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        logger.error(f"Error loading credentials: {str(e)}")
        return None

def save_credentials(file_path, credentials):
    """Save credentials to YAML file"""
    try:
        with open(file_path, 'w') as file:
            yaml.dump(credentials, file, default_flow_style=False)
        logger.info(f"Credentials saved to {file_path}")
        return True
    except Exception as e:
        logger.error(f"Error saving credentials: {str(e)}")
        return False

def backup_credentials(file_path):
    """Backup credentials file"""
    backup_path = f"{file_path}.bak"
    try:
        with open(file_path, 'r') as src:
            with open(backup_path, 'w') as dst:
                dst.write(src.read())
        logger.info(f"Credentials backed up to {backup_path}")
        return True
    except Exception as e:
        logger.error(f"Error backing up credentials: {str(e)}")
        return False

def restore_credentials(file_path):
    """Restore credentials from backup"""
    backup_path = f"{file_path}.bak"
    try:
        if not os.path.exists(backup_path):
            logger.error(f"Backup file {backup_path} not found")
            return False
            
        with open(backup_path, 'r') as src:
            with open(file_path, 'w') as dst:
                dst.write(src.read())
        logger.info(f"Credentials restored from {backup_path}")
        return True
    except Exception as e:
        logger.error(f"Error restoring credentials: {str(e)}")
        return False

def create_test_config(file_path):
    """Create a test configuration with a non-existent Redmine URL"""
    # First backup the original
    if not backup_credentials(file_path):
        return False
        
    # Load existing credentials
    creds = load_credentials(file_path)
    if not creds:
        return False
        
    # Update with a non-existent Redmine URL
    creds['redmine_url'] = "http://non-existent-redmine-server:3000"
    
    # Save the modified credentials
    return save_credentials(file_path, creds)

def test_health_endpoint(mcp_url):
    """Test the health endpoint to see how it handles unavailable Redmine"""
    try:
        response = requests.get(f"{mcp_url}/api/health", timeout=10)
        logger.info(f"Health check status code: {response.status_code}")
        
        if response.status_code == 200:
            # Parse and pretty-print the response
            health_data = response.json()
            logger.info(f"Health check response:\n{json.dumps(health_data, indent=2)}")
            
            # Check Redmine status
            redmine_status = health_data.get('services', {}).get('redmine', {}).get('status')
            if redmine_status in ('unavailable', 'unhealthy', 'api_error'):
                logger.info(f"✅ Successfully detected unavailable Redmine: {redmine_status}")
            else:
                logger.warning(f"❌ Failed to detect unavailable Redmine. Status: {redmine_status}")
                
            return health_data
        else:
            logger.error(f"Health check failed with status code {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error testing health endpoint: {str(e)}")
        return None

def main():
    """Main function"""
    args = parse_args()
    
    # Handle relative path
    creds_path = args.credentials
    if not os.path.isabs(creds_path):
        creds_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), creds_path)
    
    if args.create_test_config:
        logger.info("Creating test configuration with non-existent Redmine URL...")
        if create_test_config(creds_path):
            logger.info("✅ Test configuration created successfully")
            # Wait for MCP to reload configuration
            logger.info("Waiting for MCP to reload configuration (5 seconds)...")
            import time
            time.sleep(5)
        else:
            logger.error("❌ Failed to create test configuration")
            return 1
    
    # Test the health endpoint
    logger.info(f"Testing MCP health endpoint at {args.mcp_url}...")
    health_data = test_health_endpoint(args.mcp_url)
    
    # Test creating an issue with unavailable Redmine
    logger.info("Testing issue creation with unavailable Redmine...")
    try:
        response = requests.post(
            f"{args.mcp_url}/api/llm/create_issue",
            json={"prompt": "Create a test issue with unavailable Redmine"},
            timeout=10
        )
        logger.info(f"Issue creation status code: {response.status_code}")
        if response.status_code in (200, 201):
            logger.info(f"Issue creation response:\n{json.dumps(response.json(), indent=2)}")
        else:
            error_text = response.text if len(response.text) < 200 else response.text[:200] + "..."
            logger.error(f"Issue creation failed: {error_text}")
    except Exception as e:
        logger.error(f"Error testing issue creation: {str(e)}")
    
    # Restore the original configuration if requested
    if args.restore_config:
        logger.info("Restoring original configuration...")
        if restore_credentials(creds_path):
            logger.info("✅ Original configuration restored successfully")
        else:
            logger.error("❌ Failed to restore original configuration")
            return 1
    
    logger.info("✅ Test completed. You may need to restart the MCP service to reload the configuration.")
    return 0

if __name__ == "__main__":
    sys.exit(main())