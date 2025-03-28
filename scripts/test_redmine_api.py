#!/usr/bin/env python3
"""
Script to test the Redmine API connection.
This is used in GitHub Actions workflows and can also be run locally.

Usage:
    python scripts/test_redmine_api.py

Environment variables:
    REDMINE_URL - If set, this URL will be used instead of reading from credentials.yaml
    REDMINE_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
"""

import os
import sys
import yaml
import requests
import argparse

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test the Redmine API connection")
    parser.add_argument("--verbose", "-v", action="store_true", 
                      help="Enable verbose output")
    parser.add_argument("--create-issue", "-c", action="store_true",
                      help="Create a test issue to verify write access")
    return parser.parse_args()

def get_credentials():
    """Get Redmine credentials from environment or credentials file"""
    # First check environment variables
    redmine_url = os.environ.get("REDMINE_URL")
    redmine_api_key = os.environ.get("REDMINE_API_KEY")
    
    if redmine_url and redmine_api_key:
        print("Using Redmine credentials from environment variables")
        return redmine_url, redmine_api_key
    
    # Then check credentials.yaml
    try:
        with open("credentials.yaml", "r") as f:
            credentials = yaml.safe_load(f)
            
            redmine_url = credentials.get("redmine_url")
            redmine_api_key = credentials.get("redmine_api_key")
            
            if redmine_url and redmine_api_key and redmine_api_key != "your_redmine_api_key_here":
                print("Using Redmine credentials from credentials.yaml")
                # Ensure the URL doesn't end with a slash
                if redmine_url.endswith("/"):
                    redmine_url = redmine_url[:-1]
                return redmine_url, redmine_api_key
    except Exception as e:
        print(f"Error reading credentials.yaml: {e}")
    
    return None, None

def test_redmine_connection(url, api_key, verbose=False):
    """Test connection to Redmine API"""
    print("Testing Redmine API connection...")
    
    # Test endpoint for users (current user)
    endpoint = f"{url}/users/current.json"
    headers = {
        "X-Redmine-API-Key": api_key,
        "Content-Type": "application/json"
    }
    
    try:
        print(f"Sending request to Redmine API: {endpoint}")
        response = requests.get(endpoint, headers=headers)
        response.raise_for_status()
        
        user_data = response.json()
        
        if verbose:
            print(f"Status Code: {response.status_code}")
            print(f"User data: {user_data}")
            
        print(f"✅ Redmine API connection successful! Authenticated as: {user_data['user']['login']}")
        return True
    except requests.exceptions.HTTPError as e:
        print(f"❌ Redmine API HTTP error: {e}")
        print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Redmine API connection failed: {e}")
        return False

def create_test_issue(url, api_key, verbose=False):
    """Create a test issue in Redmine"""
    print("Creating a test issue in Redmine...")
    
    endpoint = f"{url}/issues.json"
    headers = {
        "X-Redmine-API-Key": api_key,
        "Content-Type": "application/json"
    }
    
    # Find the first available project
    try:
        projects_response = requests.get(f"{url}/projects.json", headers=headers)
        projects_response.raise_for_status()
        projects = projects_response.json()["projects"]
        
        if not projects:
            print("❌ No projects found in Redmine. Cannot create test issue.")
            return False
        
        project_id = projects[0]["id"]
    except Exception as e:
        print(f"❌ Failed to get projects: {e}")
        return False
    
    # Create a test issue
    issue_data = {
        "issue": {
            "project_id": project_id,
            "subject": "CI Test Issue",
            "description": "This is a test issue created by the CI pipeline to verify API functionality."
        }
    }
    
    try:
        response = requests.post(endpoint, headers=headers, json=issue_data)
        response.raise_for_status()
        
        new_issue = response.json()
        
        if verbose:
            print(f"Status Code: {response.status_code}")
            print(f"Issue data: {new_issue}")
            
        print(f"✅ Successfully created test issue #{new_issue['issue']['id']}")
        return True
    except requests.exceptions.HTTPError as e:
        print(f"❌ Redmine API HTTP error while creating issue: {e}")
        print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Failed to create test issue: {e}")
        return False

def main():
    """Main function"""
    args = parse_args()
    
    # Get Redmine credentials
    redmine_url, redmine_api_key = get_credentials()
    
    if not redmine_url or not redmine_api_key:
        print("❌ No valid Redmine credentials found in environment or credentials.yaml")
        print("Please set the REDMINE_URL and REDMINE_API_KEY environment variables")
        print("or add them to credentials.yaml")
        sys.exit(1)
    
    # Test the basic API connection
    connection_success = test_redmine_connection(redmine_url, redmine_api_key, args.verbose)
    
    if not connection_success:
        sys.exit(1)
    
    # Optionally create a test issue
    if args.create_issue:
        issue_success = create_test_issue(redmine_url, redmine_api_key, args.verbose)
        if not issue_success:
            sys.exit(1)
    
    print("All Redmine API tests passed successfully!")
    sys.exit(0)

if __name__ == "__main__":
    main()