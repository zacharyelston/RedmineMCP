#!/usr/bin/env python3
"""
Unified API testing script for the Redmine MCP Extension.
Tests connections to Redmine, Claude and OpenAI APIs.

Usage:
    python scripts/test_api.py redmine [--verbose] [--create-issue]
    python scripts/test_api.py claude [--verbose]
    python scripts/test_api.py openai [--verbose]
    python scripts/test_api.py all [--verbose]
    
Environment Variables:
    REDMINE_URL - If set, this URL will be used instead of reading from credentials.yaml
    REDMINE_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
    CLAUDE_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
    OPENAI_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
"""

import os
import sys
import yaml
import json
import requests
import argparse

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test API connections for Redmine MCP Extension")
    
    # Create subparsers for each API
    subparsers = parser.add_subparsers(dest="api", help="API to test")
    
    # Redmine API parser
    redmine_parser = subparsers.add_parser("redmine", help="Test Redmine API connection")
    redmine_parser.add_argument("--verbose", "-v", action="store_true", 
                             help="Enable verbose output")
    redmine_parser.add_argument("--create-issue", "-c", action="store_true",
                             help="Create a test issue to verify write access")
    
    # Claude API parser
    claude_parser = subparsers.add_parser("claude", help="Test Claude API connection")
    claude_parser.add_argument("--verbose", "-v", action="store_true", 
                            help="Enable verbose output")
    
    # OpenAI API parser
    openai_parser = subparsers.add_parser("openai", help="Test OpenAI API connection")
    openai_parser.add_argument("--verbose", "-v", action="store_true", 
                            help="Enable verbose output")
    
    # All APIs parser
    all_parser = subparsers.add_parser("all", help="Test all API connections")
    all_parser.add_argument("--verbose", "-v", action="store_true", 
                         help="Enable verbose output")
    
    args = parser.parse_args()
    
    # If no API specified, show help and exit
    if not args.api:
        parser.print_help()
        sys.exit(1)
        
    return args

def load_credentials():
    """Load credentials from credentials.yaml file"""
    try:
        with open("credentials.yaml", "r") as f:
            credentials = yaml.safe_load(f)
            return credentials
    except Exception as e:
        print(f"Error reading credentials.yaml: {e}")
        return {}

#
# Redmine API Functions
#
def get_redmine_credentials():
    """Get Redmine credentials from environment or credentials file"""
    # First check environment variables
    redmine_url = os.environ.get("REDMINE_URL")
    redmine_api_key = os.environ.get("REDMINE_API_KEY")
    
    if redmine_url and redmine_api_key:
        print("Using Redmine credentials from environment variables")
        return redmine_url, redmine_api_key
    
    # Then check credentials.yaml
    credentials = load_credentials()
    redmine_url = credentials.get("redmine_url")
    redmine_api_key = credentials.get("redmine_api_key")
    
    # Check for nested structure in YAML
    if not redmine_url and "redmine" in credentials:
        redmine_url = credentials["redmine"].get("url")
        redmine_api_key = credentials["redmine"].get("api_key")
        
    if redmine_url and redmine_api_key and redmine_api_key != "your_redmine_api_key_here":
        print("Using Redmine credentials from credentials.yaml")
        # Ensure the URL doesn't end with a slash
        if redmine_url.endswith("/"):
            redmine_url = redmine_url[:-1]
        return redmine_url, redmine_api_key
    
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
            "subject": "API Test Issue",
            "description": "This is a test issue created by the test_api.py script."
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

def test_redmine(args):
    """Run Redmine API tests"""
    print("\n=== Testing Redmine API ===")
    
    # Get Redmine credentials
    redmine_url, redmine_api_key = get_redmine_credentials()
    
    if not redmine_url or not redmine_api_key:
        print("❌ No valid Redmine credentials found in environment or credentials.yaml")
        print("Please set the REDMINE_URL and REDMINE_API_KEY environment variables")
        print("or add them to credentials.yaml")
        return False
    
    # Test the basic API connection
    connection_success = test_redmine_connection(redmine_url, redmine_api_key, args.verbose)
    
    if not connection_success:
        return False
    
    # Optionally create a test issue
    if args.create_issue:
        issue_success = create_test_issue(redmine_url, redmine_api_key, args.verbose)
        if not issue_success:
            return False
    
    print("All Redmine API tests passed successfully!")
    return True

#
# Claude API Functions
#
def get_claude_api_key():
    """Get Claude API key from environment or credentials file"""
    # First check environment variable
    api_key = os.environ.get("CLAUDE_API_KEY")
    
    if api_key:
        print("Using Claude API key from environment variable")
        return api_key
    
    # Then check credentials.yaml
    credentials = load_credentials()
    
    # Try both flattened and nested structures
    api_key = credentials.get("claude_api_key")
    if not api_key and "claude" in credentials:
        api_key = credentials["claude"].get("api_key")
        
    if api_key and api_key != "your_claude_api_key_here":
        print("Using Claude API key from credentials.yaml")
        return api_key
    
    return None

def test_claude_connection(api_key, verbose=False):
    """Test connection to Anthropic Claude API"""
    print("Testing Claude API connection...")
    
    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    
    # Sample minimal request body
    data = {
        "model": "claude-3-haiku-20240307",  # Using smallest model for quick test
        "max_tokens": 1,
        "messages": [
            {"role": "user", "content": "Hello, Claude!"}
        ]
    }
    
    try:
        print("Sending request to Claude API...")
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        
        # If we get here, the request was successful
        print("✅ Claude API connection successful!")
        
        if verbose:
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
        
        return True
    except requests.exceptions.HTTPError as e:
        print(f"❌ Claude API HTTP error: {e}")
        print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Claude API connection failed: {e}")
        return False

def test_claude(args):
    """Run Claude API tests"""
    print("\n=== Testing Claude API ===")
    
    # Get API key
    api_key = get_claude_api_key()
    
    if not api_key:
        print("❌ No valid Claude API key found in environment or credentials.yaml")
        print("Please set the CLAUDE_API_KEY environment variable or add it to credentials.yaml")
        return False
    
    # Test the connection
    success = test_claude_connection(api_key, args.verbose)
    
    if not success:
        return False
        
    print("All Claude API tests passed successfully!")
    return True

#
# OpenAI API Functions
#
def get_openai_api_key():
    """Get OpenAI API key from environment or credentials file"""
    # First check environment variable
    api_key = os.environ.get("OPENAI_API_KEY")
    
    if api_key:
        print("Using OpenAI API key from environment variable")
        return api_key
    
    # Then check credentials.yaml
    credentials = load_credentials()
    
    # Try both flattened and nested structures
    api_key = credentials.get("openai_api_key")
    if not api_key and "openai" in credentials:
        api_key = credentials["openai"].get("api_key")
        
    if api_key and api_key != "your_openai_api_key_here":
        print("Using OpenAI API key from credentials.yaml")
        return api_key
    
    return None

def test_openai_connection(api_key, verbose=False):
    """Test connection to OpenAI API"""
    print("Testing OpenAI API connection...")
    
    try:
        # Dynamically import openai to avoid errors if not installed
        import openai
        client = openai.OpenAI(api_key=api_key)
        
        print("Sending request to OpenAI API...")
        # Using simplest model for a quick test
        response = client.chat.completions.create(
            model="gpt-4o",  # The newest OpenAI model
            messages=[
                {"role": "user", "content": "Hello, GPT!"}
            ],
            max_tokens=1
        )
        
        # If we get here, the request was successful
        print("✅ OpenAI API connection successful!")
        
        if verbose:
            print(f"Response: {response}")
        
        return True
    except Exception as e:
        print(f"❌ OpenAI API connection failed: {e}")
        return False

def test_openai(args):
    """Run OpenAI API tests"""
    print("\n=== Testing OpenAI API ===")
    
    # Get API key
    api_key = get_openai_api_key()
    
    if not api_key:
        print("❌ No valid OpenAI API key found in environment or credentials.yaml")
        print("Please set the OPENAI_API_KEY environment variable or add it to credentials.yaml")
        return False
    
    try:
        # Dynamically try to import OpenAI - require the user to have it installed
        import openai
    except ImportError:
        print("❌ OpenAI Python package not installed. Please install it with 'pip install openai'.")
        return False
    
    # Test the connection
    success = test_openai_connection(api_key, args.verbose)
    
    if not success:
        return False
        
    print("All OpenAI API tests passed successfully!")
    return True


def main():
    """Main function"""
    args = parse_args()
    success = False
    
    if args.api == "redmine":
        success = test_redmine(args)
    elif args.api == "claude":
        success = test_claude(args)
    elif args.api == "openai":
        success = test_openai(args)
    elif args.api == "all":
        # Test all APIs
        redmine_args = argparse.Namespace(verbose=args.verbose, create_issue=False)
        claude_args = argparse.Namespace(verbose=args.verbose)
        openai_args = argparse.Namespace(verbose=args.verbose)
        
        redmine_success = test_redmine(redmine_args)
        claude_success = test_claude(claude_args)
        openai_success = test_openai(openai_args)
        
        success = redmine_success and claude_success and openai_success
    
    if not success:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()