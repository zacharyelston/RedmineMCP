#!/usr/bin/env python3
"""
Simple script to check Redmine and MCP container availability
"""

import sys
import requests
import yaml
import os

def load_config():
    """Load configuration from credentials.yaml"""
    try:
        with open('credentials.yaml', 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        print(f"Error loading credentials: {e}")
        return {}

def check_redmine():
    """Check if Redmine is accessible"""
    try:
        print("Checking Redmine server...")
        response = requests.get('http://localhost:3000', timeout=5)
        print(f"Redmine status: {response.status_code}")
        print(f"Redmine is {'running' if response.status_code == 200 else 'not available properly'}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error connecting to Redmine: {e}")
        return False

def check_mcp():
    """Check if MCP extension is accessible"""
    try:
        print("\nChecking MCP extension...")
        response = requests.get('http://localhost:9000/api/health', timeout=5)
        print(f"MCP status: {response.status_code}")
        print(f"MCP is {'running' if response.status_code == 200 else 'not available properly'}")
        
        if response.status_code == 200:
            health = response.json()
            print(f"\nMCP Health details:")
            print(f"  Version: {health.get('version', 'unknown')}")
            print(f"  Status: {health.get('status', 'unknown')}")
            
            services = health.get('services', {})
            for service, details in services.items():
                print(f"  {service}: {details.get('status', 'unknown')}")
        
        return response.status_code == 200
    except Exception as e:
        print(f"Error connecting to MCP extension: {e}")
        return False

def check_trackers():
    """Check if trackers exist in Redmine"""
    config = load_config()
    api_key = config.get('redmine_api_key')
    
    if not api_key:
        print("No API key found in credentials.yaml")
        return False
    
    try:
        print("\nChecking Redmine trackers...")
        response = requests.get(
            'http://localhost:3000/trackers.json',
            headers={'X-Redmine-API-Key': api_key},
            timeout=5
        )
        
        if response.status_code == 200:
            trackers = response.json().get('trackers', [])
            print(f"Found {len(trackers)} trackers:")
            for tracker in trackers:
                print(f"  - {tracker.get('name')} (ID: {tracker.get('id')})")
            return len(trackers) > 0
        else:
            print(f"Failed to get trackers. Status: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error checking trackers: {e}")
        return False

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    print("Testing Redmine MCP container setup...")
    redmine_ok = check_redmine()
    mcp_ok = check_mcp()
    trackers_ok = check_trackers() if redmine_ok else False
    
    print("\nSummary:")
    print(f"Redmine server: {'✅' if redmine_ok else '❌'}")
    print(f"MCP extension: {'✅' if mcp_ok else '❌'}")
    print(f"Redmine trackers: {'✅' if trackers_ok else '❌'}")
    
    if not (redmine_ok and mcp_ok):
        print("\nContainers don't appear to be running or accessible.")
        print("You may need to start them with: docker-compose -f docker-compose.local.yml up -d")
    elif not trackers_ok:
        print("\nTrackers are missing. You can create them with:")
        print("python scripts/bootstrap_redmine_simple.py")
    else:
        print("\nSetup is complete and working correctly! ✅")
