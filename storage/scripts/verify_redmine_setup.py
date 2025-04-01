#!/usr/bin/env python3
"""
Redmine Setup Verification Script

This script checks if a Redmine instance has the minimum required configuration
for API connections from agents.

Usage:
  python scripts/verify_redmine_setup.py --url=http://localhost:3000 --api-key=your_api_key
  
Options:
  --url            URL of the Redmine instance (default: http://localhost:3000)
  --api-key        Admin API key for Redmine
  --credentials    Path to credentials.yaml file (default: ../credentials.yaml)
  --verbose        Show verbose output
"""

import argparse
import json
import logging
import os
import sys
import yaml
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Verify Redmine setup for API connections')
    parser.add_argument('--url', default='http://localhost:3000', help='URL of the Redmine instance')
    parser.add_argument('--api-key', help='Admin API key for Redmine')
    parser.add_argument('--credentials', default='../credentials.yaml', help='Path to credentials.yaml file')
    parser.add_argument('--verbose', action='store_true', help='Show verbose output')
    return parser.parse_args()

def load_credentials(credentials_path):
    """Load credentials from YAML file"""
    if not os.path.exists(credentials_path):
        logger.warning(f"Credentials file not found: {credentials_path}")
        return {}
    
    try:
        with open(credentials_path, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        logger.error(f"Error loading credentials: {str(e)}")
        return {}

class RedmineVerifier:
    """Class to verify Redmine setup"""
    
    def __init__(self, url, api_key, verbose=False):
        """Initialize the verifier"""
        self.redmine_url = url.rstrip('/')
        self.api_key = api_key
        self.verbose = verbose
        self.session = requests.Session()
        self.session.headers.update({
            'X-Redmine-API-Key': self.api_key,
            'Content-Type': 'application/json'
        })
        
        # Resource tracking
        self.resources = {
            "users": [],
            "groups": [],
            "trackers": [],
            "statuses": [],
            "priorities": [],
            "roles": [],
            "projects": [],
            "custom_fields": [],
            "memberships": []
        }
        
        # Minimum requirements
        self.requirements = {
            "users": 1,        # At least one user
            "trackers": 1,     # At least one tracker
            "statuses": 2,     # At least two statuses (open and closed)
            "priorities": 1,   # At least one priority
            "roles": 1,        # At least one role
            "projects": 1,     # At least one project
            "api_key_valid": False  # API key validity
        }
        
        # Results
        self.results = {
            "users": False,
            "trackers": False,
            "statuses": False,
            "priorities": False,
            "roles": False,
            "projects": False,
            "api_key_valid": False,
            "overall": False
        }
    
    def _log_request(self, response):
        """Log API request details if verbose mode is enabled"""
        if self.verbose:
            try:
                logger.debug(f"Request: {response.request.method} {response.request.url}")
                logger.debug(f"Request headers: {response.request.headers}")
                logger.debug(f"Response status: {response.status_code}")
                logger.debug(f"Response headers: {response.headers}")
                logger.debug(f"Response body: {json.dumps(response.json(), indent=2)}")
            except:
                logger.debug(f"Response text: {response.text[:200]}...")
    
    def _make_request(self, method, endpoint, data=None, params=None):
        """Make a request to the Redmine API"""
        url = f"{self.redmine_url}/{endpoint}"
        try:
            response = self.session.request(
                method=method,
                url=url,
                json=data,
                params=params,
                timeout=10
            )
            self._log_request(response)
            response.raise_for_status()
            
            if response.status_code == 204:  # No content
                return {"success": True}
                
            return response.json()
        except requests.exceptions.RequestException as e:
            if self.verbose:
                logger.error(f"API request failed: {str(e)}")
                if hasattr(e, 'response') and e.response is not None:
                    try:
                        error_detail = e.response.json()
                        logger.error(f"Error details: {json.dumps(error_detail, indent=2)}")
                    except:
                        logger.error(f"Error response: {e.response.text}")
            return None
        except Exception as e:
            if self.verbose:
                logger.error(f"Unexpected error: {str(e)}")
            return None
    
    def verify_api_key(self):
        """Verify that the API key is valid"""
        logger.info(f"Testing connection to Redmine at {self.redmine_url}...")
        try:
            response = self._make_request('GET', 'users/current.json')
            if response and 'user' in response:
                user = response.get('user', {})
                logger.info(f"✅ Connection successful! Logged in as: {user.get('login')} (Admin: {user.get('admin')})")
                
                if not user.get('admin'):
                    logger.warning("⚠️ Warning: The API key provided does not belong to an admin user.")
                    logger.warning("Some verification operations may fail due to insufficient permissions.")
                
                self.results["api_key_valid"] = True
                return True
            else:
                logger.error("❌ Connection test failed: Invalid response")
                return False
        except Exception as e:
            logger.error(f"❌ Connection test failed: {str(e)}")
            return False
    
    def get_resources(self):
        """Get resources from Redmine"""
        # Get users
        response = self._make_request('GET', 'users.json', params={'limit': 100})
        if response and 'users' in response:
            self.resources["users"] = response.get('users', [])
        
        # Get trackers
        response = self._make_request('GET', 'trackers.json')
        if response and 'trackers' in response:
            self.resources["trackers"] = response.get('trackers', [])
        
        # Get issue statuses
        response = self._make_request('GET', 'issue_statuses.json')
        if response and 'issue_statuses' in response:
            self.resources["statuses"] = response.get('issue_statuses', [])
        
        # Get priorities
        response = self._make_request('GET', 'enumerations/issue_priorities.json')
        if response and 'issue_priorities' in response:
            self.resources["priorities"] = response.get('issue_priorities', [])
        
        # Get roles
        response = self._make_request('GET', 'roles.json')
        if response and 'roles' in response:
            self.resources["roles"] = response.get('roles', [])
        
        # Get projects
        response = self._make_request('GET', 'projects.json', params={'limit': 100})
        if response and 'projects' in response:
            self.resources["projects"] = response.get('projects', [])
    
    def check_requirements(self):
        """Check if the requirements are met"""
        self.results["users"] = len(self.resources["users"]) >= self.requirements["users"]
        self.results["trackers"] = len(self.resources["trackers"]) >= self.requirements["trackers"]
        self.results["statuses"] = len(self.resources["statuses"]) >= self.requirements["statuses"]
        self.results["priorities"] = len(self.resources["priorities"]) >= self.requirements["priorities"]
        self.results["roles"] = len(self.resources["roles"]) >= self.requirements["roles"]
        self.results["projects"] = len(self.resources["projects"]) >= self.requirements["projects"]
        
        # Overall result
        self.results["overall"] = all([
            self.results["api_key_valid"],
            self.results["users"],
            self.results["trackers"],
            self.results["statuses"],
            self.results["priorities"],
            self.results["roles"],
            self.results["projects"]
        ])
    
    def verify(self):
        """Verify the Redmine setup"""
        # Verify API key
        if not self.verify_api_key():
            return False
        
        # Get resources
        self.get_resources()
        
        # Check requirements
        self.check_requirements()
        
        # Print results
        self.print_results()
        
        return self.results["overall"]
    
    def print_results(self):
        """Print verification results"""
        logger.info("\n" + "="*70)
        logger.info("REDMINE SETUP VERIFICATION RESULTS")
        logger.info("="*70)
        
        logger.info(f"API Key: {'✅ Valid' if self.results['api_key_valid'] else '❌ Invalid'}")
        logger.info(f"Users: {'✅ OK' if self.results['users'] else '❌ Missing'} ({len(self.resources['users'])} found, {self.requirements['users']} required)")
        logger.info(f"Trackers: {'✅ OK' if self.results['trackers'] else '❌ Missing'} ({len(self.resources['trackers'])} found, {self.requirements['trackers']} required)")
        logger.info(f"Issue Statuses: {'✅ OK' if self.results['statuses'] else '❌ Missing'} ({len(self.resources['statuses'])} found, {self.requirements['statuses']} required)")
        logger.info(f"Priorities: {'✅ OK' if self.results['priorities'] else '❌ Missing'} ({len(self.resources['priorities'])} found, {self.requirements['priorities']} required)")
        logger.info(f"Roles: {'✅ OK' if self.results['roles'] else '❌ Missing'} ({len(self.resources['roles'])} found, {self.requirements['roles']} required)")
        logger.info(f"Projects: {'✅ OK' if self.results['projects'] else '❌ Missing'} ({len(self.resources['projects'])} found, {self.requirements['projects']} required)")
        
        if self.verbose:
            # Print detailed resource information
            if self.resources["trackers"]:
                tracker_names = [t.get('name') for t in self.resources["trackers"]]
                logger.info(f"Available trackers: {', '.join(tracker_names)}")
            
            if self.resources["statuses"]:
                status_names = [s.get('name') for s in self.resources["statuses"]]
                logger.info(f"Available statuses: {', '.join(status_names)}")
            
            if self.resources["priorities"]:
                priority_names = [p.get('name') for p in self.resources["priorities"]]
                logger.info(f"Available priorities: {', '.join(priority_names)}")
            
            if self.resources["projects"]:
                project_names = [p.get('name') for p in self.resources["projects"]]
                logger.info(f"Available projects: {', '.join(project_names)}")
        
        logger.info("="*70)
        logger.info(f"Overall Status: {'✅ Ready for API connections' if self.results['overall'] else '❌ Not ready - bootstrap required'}")
        if not self.results["overall"]:
            logger.info("Run bootstrap_redmine.py to set up the required configuration")
        logger.info("="*70)

def main():
    """Main function"""
    args = parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Handle relative path for credentials
    creds_path = args.credentials
    if not os.path.isabs(creds_path):
        creds_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), creds_path)
    
    # Get API key - either from command line or credentials file
    api_key = args.api_key
    if not api_key:
        credentials = load_credentials(creds_path)
        if credentials:
            api_key = credentials.get('redmine_api_key')
    
    if not api_key:
        logger.error("No Redmine API key provided. Please specify via --api-key or in credentials.yaml")
        return 1
    
    # Create verifier instance
    redmine_url = args.url
    verifier = RedmineVerifier(redmine_url, api_key, args.verbose)
    
    # Run verification
    result = verifier.verify()
    
    return 0 if result else 1

if __name__ == "__main__":
    sys.exit(main())