#!/usr/bin/env python3
"""
Script to test the MCP integration with Redmine
This simulates MCP client requests to verify the extension is working correctly
"""

import argparse
import json
import sys
import time
from urllib.parse import urljoin

import requests

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test MCP integration with Redmine")
    parser.add_argument(
        "--base-url",
        default="http://localhost:5000",
        help="Base URL of the MCP extension (default: http://localhost:5000)",
    )
    parser.add_argument(
        "--project-id",
        default="1",
        help="Redmine project ID for testing issue creation (default: 1)",
    )
    parser.add_argument(
        "--issue-id",
        help="Existing Redmine issue ID for testing update and analyze operations",
    )
    parser.add_argument(
        "--action",
        choices=["create", "update", "analyze", "all"],
        default="all",
        help="Action to test (default: all)",
    )
    
    return parser.parse_args()

def check_capabilities(base_url):
    """Test checking MCP capabilities"""
    print("Testing MCP capabilities endpoint...")
    capabilities_url = urljoin(base_url, "/api/capabilities")
    
    try:
        response = requests.get(capabilities_url)
        response.raise_for_status()
        capabilities = response.json()
        
        print("✅ MCP capabilities endpoint is working")
        print("Available capabilities:")
        for capability, details in capabilities.items():
            print(f"  - {capability}: {details.get('description', 'No description')}")
        
        return True
    except Exception as e:
        print(f"❌ Failed to get MCP capabilities: {e}")
        return False

def check_health(base_url):
    """Test checking MCP health endpoint"""
    print("\nTesting MCP health endpoint...")
    health_url = urljoin(base_url, "/api/health")
    
    try:
        response = requests.get(health_url)
        response.raise_for_status()
        health = response.json()
        
        print("✅ MCP health endpoint is working")
        print(f"Status: {health.get('status', 'Unknown')}")
        print(f"Redmine connection: {health.get('redmine_connection', 'Unknown')}")
        print(f"Claude connection: {health.get('claude_connection', 'Unknown')}")
        
        if health.get("status") != "healthy":
            print("⚠️ The MCP extension is not fully healthy")
            return False
        
        return True
    except Exception as e:
        print(f"❌ Failed to get MCP health status: {e}")
        return False

def create_issue(base_url, project_id):
    """Test creating an issue via MCP"""
    print("\nTesting issue creation...")
    create_url = urljoin(base_url, "/api/llm/create_issue")
    
    payload = {
        "prompt": "Create a high-priority bug report about a UI rendering issue in the admin dashboard. "
                "The problem occurs in Chrome and Firefox browsers, where the sidebar navigation "
                "disappears after switching between tabs. This started happening after the latest update.",
        "project_id": project_id
    }
    
    try:
        start_time = time.time()
        response = requests.post(create_url, json=payload)
        response.raise_for_status()
        elapsed_time = time.time() - start_time
        
        result = response.json()
        
        print(f"✅ Issue created successfully in {elapsed_time:.2f} seconds")
        print(f"Issue ID: {result.get('issue_id')}")
        print(f"Subject: {result.get('subject')}")
        print("Description:")
        print(f"{result.get('description')[:200]}...")  # Show first 200 chars
        
        return result.get("issue_id")
    except requests.RequestException as e:
        print(f"❌ Failed to create issue: {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"Response: {e.response.text}")
        return None

def update_issue(base_url, issue_id):
    """Test updating an issue via MCP"""
    print("\nTesting issue update...")
    update_url = urljoin(base_url, f"/api/llm/update_issue/{issue_id}")
    
    payload = {
        "prompt": "Update this issue to include the information that the bug also affects Safari on macOS. "
                "Change the priority to urgent as this is affecting many users and needs to be fixed "
                "before the next sprint."
    }
    
    try:
        start_time = time.time()
        response = requests.post(update_url, json=payload)
        response.raise_for_status()
        elapsed_time = time.time() - start_time
        
        result = response.json()
        
        print(f"✅ Issue updated successfully in {elapsed_time:.2f} seconds")
        print(f"Changes: {result.get('changes', 'No details available')}")
        
        return True
    except requests.RequestException as e:
        print(f"❌ Failed to update issue: {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"Response: {e.response.text}")
        return False

def analyze_issue(base_url, issue_id):
    """Test analyzing an issue via MCP"""
    print("\nTesting issue analysis...")
    analyze_url = urljoin(base_url, f"/api/llm/analyze_issue/{issue_id}")
    
    try:
        start_time = time.time()
        response = requests.post(analyze_url, json={})
        response.raise_for_status()
        elapsed_time = time.time() - start_time
        
        result = response.json()
        
        print(f"✅ Issue analyzed successfully in {elapsed_time:.2f} seconds")
        print("Analysis summary:")
        
        if "summary" in result:
            print(f"Summary: {result['summary']}")
        
        if "risk_assessment" in result:
            print(f"Risk assessment: {result['risk_assessment']}")
        
        if "recommendations" in result and isinstance(result["recommendations"], list):
            print("Recommendations:")
            for rec in result["recommendations"]:
                print(f"  - {rec}")
        
        return True
    except requests.RequestException as e:
        print(f"❌ Failed to analyze issue: {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"Response: {e.response.text}")
        return False

def main():
    """Main function"""
    args = parse_args()
    
    print("🚀 MCP Integration Test")
    print(f"Base URL: {args.base_url}")
    
    # Always check capabilities and health first
    if not check_capabilities(args.base_url) or not check_health(args.base_url):
        print("\n❌ Basic MCP endpoints aren't working correctly. Aborting tests.")
        sys.exit(1)
    
    # Track the created issue ID if we need it for later tests
    created_issue_id = None
    
    # Run the requested tests
    if args.action in ["create", "all"]:
        created_issue_id = create_issue(args.base_url, args.project_id)
    
    # Use the provided issue ID or the one we just created
    test_issue_id = args.issue_id or created_issue_id
    
    if not test_issue_id and args.action in ["update", "analyze", "all"]:
        print("\n❌ No issue ID available for update/analyze tests.")
        print("Please provide an --issue-id argument or ensure issue creation succeeds.")
        sys.exit(1)
    
    if args.action in ["update", "all"]:
        update_issue(args.base_url, test_issue_id)
    
    if args.action in ["analyze", "all"]:
        analyze_issue(args.base_url, test_issue_id)
    
    print("\n🎉 MCP integration test complete!")

if __name__ == "__main__":
    main()