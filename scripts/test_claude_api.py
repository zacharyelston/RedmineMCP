#!/usr/bin/env python3
"""
Script to test connection to Anthropic's Claude API.
This is used in GitHub Actions workflows and can also be run locally.

Usage:
    python scripts/test_claude_api.py
    
Environment Variables:
    CLAUDE_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
"""

import os
import sys
import yaml
import requests
import argparse

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test the Claude API connection")
    parser.add_argument("--verbose", "-v", action="store_true", 
                      help="Enable verbose output")
    return parser.parse_args()

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

def get_api_key():
    """Get API key from environment or credentials file"""
    # First check environment variable
    api_key = os.environ.get("CLAUDE_API_KEY")
    
    if api_key:
        print("Using Claude API key from environment variable")
        return api_key
    
    # Then check credentials.yaml
    try:
        with open("credentials.yaml", "r") as f:
            credentials = yaml.safe_load(f)
            api_key = credentials.get("claude_api_key")
            
            if api_key and api_key != "your_claude_api_key_here":
                print("Using Claude API key from credentials.yaml")
                return api_key
    except Exception as e:
        print(f"Error reading credentials.yaml: {e}")
    
    return None

def main():
    """Main function"""
    args = parse_args()
    
    # Get API key
    api_key = get_api_key()
    
    if not api_key:
        print("❌ No valid Claude API key found in environment or credentials.yaml")
        print("Please set the CLAUDE_API_KEY environment variable or add it to credentials.yaml")
        sys.exit(1)
    
    # Test the connection
    success = test_claude_connection(api_key, args.verbose)
    
    if not success:
        sys.exit(1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()