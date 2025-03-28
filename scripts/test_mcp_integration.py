#!/usr/bin/env python3
"""
Script to test the MCP integration with Redmine
This simulates MCP client requests to verify the extension is working correctly
"""

import os
import sys
import json
import yaml
import requests
import argparse

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test the MCP integration")
    parser.add_argument("--base-url", default="http://localhost:5000",
                        help="Base URL of the MCP extension (default: http://localhost:5000)")
    parser.add_argument("--project-id", help="Redmine project ID for testing issue creation")
    parser.add_argument("--issue-id", help="Redmine issue ID for testing issue updates and analysis")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose output")
    return parser.parse_args()

def check_capabilities(base_url):
    """Test checking MCP capabilities"""
    print("Testing MCP capabilities endpoint...")
    
    endpoint = f"{base_url}/api/capabilities"
    
    try:
        response = requests.get(endpoint)
        response.raise_for_status()
        
        capabilities = response.json()
        print("✅ MCP capabilities endpoint is working!")
        print(f"Returned capabilities: {json.dumps(capabilities, indent=2)}")
        return True
    except Exception as e:
        print(f"❌ Failed to get MCP capabilities: {e}")
        return False

def check_health(base_url):
    """Test checking MCP health endpoint"""
    print("Testing MCP health endpoint...")
    
    endpoint = f"{base_url}/api/health"
    
    try:
        response = requests.get(endpoint)
        response.raise_for_status()
        
        health_data = response.json()
        print("✅ MCP health endpoint is working!")
        print(f"Health status: {json.dumps(health_data, indent=2)}")
        
        if health_data.get("status") != "healthy" and health_data.get("status") != "ok":
            print(f"⚠️ Warning: Health check returned unhealthy status: {health_data.get('status')}")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Failed to get MCP health status: {e}")
        return False

def create_issue(base_url, project_id):
    """Test creating an issue via MCP"""
    print("Testing issue creation via MCP...")
    
    endpoint = f"{base_url}/api/llm/create_issue"
    
    # Sample prompt for issue creation
    data = {
        "prompt": "Create a high priority bug report for project " + 
                 f"{project_id} about the login page not working properly. " +
                 "The login button is not responding when clicked."
    }
    
    try:
        response = requests.post(endpoint, json=data)
        response.raise_for_status()
        
        result = response.json()
        print("✅ Issue creation successful!")
        print(f"Created issue: {json.dumps(result, indent=2)}")
        
        # Return the new issue ID for further testing
        return result.get("issue", {}).get("id")
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to create issue: {e}")
        if hasattr(e, 'response') and e.response is not None and hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return None
    except Exception as e:
        print(f"❌ Failed to create issue: {e}")
        return None

def update_issue(base_url, issue_id):
    """Test updating an issue via MCP"""
    print(f"Testing update of issue #{issue_id} via MCP...")
    
    endpoint = f"{base_url}/api/llm/update_issue/{issue_id}"
    
    # Sample prompt for issue update
    data = {
        "prompt": f"Update issue {issue_id} to include more details. " +
                 "Add that this issue occurs only in Chrome browsers and " +
                 "the console shows a JavaScript error."
    }
    
    try:
        response = requests.post(endpoint, json=data)
        response.raise_for_status()
        
        result = response.json()
        print("✅ Issue update successful!")
        print(f"Update result: {json.dumps(result, indent=2)}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to update issue: {e}")
        if hasattr(e, 'response') and e.response is not None and hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Failed to update issue: {e}")
        return False

def analyze_issue(base_url, issue_id):
    """Test analyzing an issue via MCP"""
    print(f"Testing analysis of issue #{issue_id} via MCP...")
    
    endpoint = f"{base_url}/api/llm/analyze_issue/{issue_id}"
    
    try:
        response = requests.post(endpoint)
        response.raise_for_status()
        
        result = response.json()
        print("✅ Issue analysis successful!")
        print(f"Analysis result: {json.dumps(result, indent=2)}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to analyze issue: {e}")
        if hasattr(e, 'response') and e.response is not None and hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Failed to analyze issue: {e}")
        return False

def main():
    """Main function"""
    args = parse_args()
    
    print(f"Testing MCP integration at {args.base_url}")
    
    # Test MCP capabilities endpoint
    if not check_capabilities(args.base_url):
        sys.exit(1)
    
    # Test MCP health endpoint
    if not check_health(args.base_url):
        sys.exit(1)
    
    # Test issue creation if project ID is provided
    issue_id = args.issue_id
    if args.project_id:
        created_issue_id = create_issue(args.base_url, args.project_id)
        if created_issue_id:
            # Use the created issue for further tests if no specific issue ID was provided
            if not issue_id:
                issue_id = created_issue_id
                print(f"Using newly created issue #{issue_id} for further tests")
    
    # Test issue update and analysis if issue ID is available
    if issue_id:
        if not update_issue(args.base_url, issue_id):
            sys.exit(1)
        
        if not analyze_issue(args.base_url, issue_id):
            sys.exit(1)
    else:
        print("⚠️ Skipping issue update and analysis tests (no issue ID available)")
    
    print("✅ All MCP integration tests passed successfully!")
    sys.exit(0)

if __name__ == "__main__":
    main()