#!/usr/bin/env python3
"""
Comprehensive test script to validate Redmine API functionality.
This script tests the integration with a Redmine server by creating a test project,
issues, and related entities to verify the API key is working correctly.
"""

import os
import sys
import json
import logging
import argparse
import requests
import random
import string
import time
from datetime import datetime, timedelta
import yaml

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Default Redmine endpoint (for local docker setup)
DEFAULT_REDMINE_URL = "http://localhost:3000"
DEFAULT_CREDENTIALS_PATH = "../credentials.yaml"

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test Redmine API functionality")
    parser.add_argument("--redmine-url", default=DEFAULT_REDMINE_URL, 
                        help="URL of the Redmine server")
    parser.add_argument("--credentials", default=DEFAULT_CREDENTIALS_PATH, 
                        help="Path to credentials.yaml file")
    parser.add_argument("--api-key", help="Redmine API key (overrides credentials file)")
    parser.add_argument("--cleanup", action="store_true", 
                        help="Clean up test data after running tests")
    parser.add_argument("--verbose", "-v", action="store_true", 
                        help="Enable verbose logging")
    return parser.parse_args()

def load_credentials(file_path):
    """Load credentials from YAML file"""
    try:
        with open(file_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        logger.error(f"Error loading credentials: {str(e)}")
        return None

def random_string(length=8):
    """Generate a random string for test data"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

class RedmineApiTester:
    """Test class for Redmine API functionality"""
    
    def __init__(self, redmine_url, api_key, verbose=False):
        self.redmine_url = redmine_url.rstrip('/')
        self.api_key = api_key
        self.verbose = verbose
        self.test_prefix = f"TEST-{random_string(4)}"
        self.created_resources = {
            "projects": [],
            "issues": [],
            "versions": [],
            "wiki_pages": []
        }
        
        # Set up request session
        self.session = requests.Session()
        self.session.headers.update({
            'X-Redmine-API-Key': self.api_key,
            'Content-Type': 'application/json'
        })
        
        if verbose:
            logging.getLogger().setLevel(logging.DEBUG)
            # Enable request logging
            import http.client as http_client
            http_client.HTTPConnection.debuglevel = 1
    
    def _log_request(self, response):
        """Log request and response details for debugging"""
        if self.verbose:
            logger.debug(f"URL: {response.request.url}")
            logger.debug(f"Method: {response.request.method}")
            logger.debug(f"Headers: {response.request.headers}")
            logger.debug(f"Body: {response.request.body}")
            logger.debug(f"Response status: {response.status_code}")
            logger.debug(f"Response headers: {response.headers}")
            try:
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
            logger.error(f"API request failed: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                try:
                    error_detail = e.response.json()
                    logger.error(f"Error details: {json.dumps(error_detail, indent=2)}")
                except:
                    logger.error(f"Error response: {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            raise
    
    def test_connection(self):
        """Test basic connection to Redmine API"""
        logger.info(f"Testing connection to Redmine at {self.redmine_url}...")
        try:
            response = self._make_request('GET', 'users/current.json')
            user = response.get('user', {})
            logger.info(f"✅ Connection successful! Logged in as: {user.get('login')} (Admin: {user.get('admin')})")
            return True
        except Exception as e:
            logger.error(f"❌ Connection test failed: {str(e)}")
            return False
    
    def get_trackers(self):
        """Get available trackers"""
        logger.info("Retrieving available trackers...")
        response = self._make_request('GET', 'trackers.json')
        trackers = response.get('trackers', [])
        logger.info(f"Found {len(trackers)} trackers")
        return trackers
    
    def get_issue_statuses(self):
        """Get available issue statuses"""
        logger.info("Retrieving available issue statuses...")
        response = self._make_request('GET', 'issue_statuses.json')
        statuses = response.get('issue_statuses', [])
        logger.info(f"Found {len(statuses)} issue statuses")
        return statuses
    
    def get_priorities(self):
        """Get available issue priorities"""
        logger.info("Retrieving available issue priorities...")
        response = self._make_request('GET', 'enumerations/issue_priorities.json')
        priorities = response.get('issue_priorities', [])
        logger.info(f"Found {len(priorities)} issue priorities")
        return priorities
    
    def create_project(self):
        """Create a test project"""
        project_identifier = f"{self.test_prefix.lower()}-proj"
        project_name = f"{self.test_prefix} Test Project"
        
        logger.info(f"Creating test project: {project_name}...")
        data = {
            "project": {
                "name": project_name,
                "identifier": project_identifier,
                "description": f"Test project created by API validation script on {datetime.now().isoformat()}",
                "is_public": False,
                "enabled_module_names": [
                    "issue_tracking", "time_tracking", "news", "documents", 
                    "files", "wiki", "repository", "calendar", "gantt"
                ]
            }
        }
        
        try:
            response = self._make_request('POST', 'projects.json', data)
            project = response.get('project', {})
            project_id = project.get('id')
            logger.info(f"✅ Project created successfully with ID: {project_id}")
            self.created_resources["projects"].append(project_id)
            return project
        except Exception as e:
            logger.error(f"❌ Project creation failed: {str(e)}")
            return None
    
    def create_version(self, project_id):
        """Create a version for the test project"""
        version_name = f"{self.test_prefix} Version 1.0"
        
        logger.info(f"Creating version for project ID {project_id}...")
        data = {
            "version": {
                "name": version_name,
                "status": "open",
                "due_date": (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d'),
                "description": "Test version created by API validation script",
                "sharing": "none"
            }
        }
        
        try:
            response = self._make_request('POST', f'projects/{project_id}/versions.json', data)
            version = response.get('version', {})
            version_id = version.get('id')
            logger.info(f"✅ Version created successfully with ID: {version_id}")
            self.created_resources["versions"].append(version_id)
            return version
        except Exception as e:
            logger.error(f"❌ Version creation failed: {str(e)}")
            return None
    
    def create_issue(self, project_id, tracker_id=None, priority_id=None, version_id=None):
        """Create a test issue"""
        issue_subject = f"{self.test_prefix} Test Issue {random_string(4)}"
        
        # Get tracker and priority IDs if not provided
        if not tracker_id:
            trackers = self.get_trackers()
            if trackers:
                tracker_id = trackers[0]['id']
        
        if not priority_id:
            priorities = self.get_priorities()
            if priorities:
                for p in priorities:
                    if p.get('name', '').lower() == 'normal':
                        priority_id = p['id']
                        break
                if not priority_id and priorities:
                    priority_id = priorities[0]['id']
        
        logger.info(f"Creating test issue for project ID {project_id}...")
        data = {
            "issue": {
                "project_id": project_id,
                "subject": issue_subject,
                "description": f"Test issue created by API validation script on {datetime.now().isoformat()}",
                "tracker_id": tracker_id,
                "priority_id": priority_id,
                "start_date": datetime.now().strftime('%Y-%m-%d')
            }
        }
        
        if version_id:
            data["issue"]["fixed_version_id"] = version_id
        
        try:
            response = self._make_request('POST', 'issues.json', data)
            issue = response.get('issue', {})
            issue_id = issue.get('id')
            logger.info(f"✅ Issue created successfully with ID: {issue_id}")
            self.created_resources["issues"].append(issue_id)
            return issue
        except Exception as e:
            logger.error(f"❌ Issue creation failed: {str(e)}")
            return None
    
    def update_issue(self, issue_id, status_id=None, notes=None):
        """Update a test issue"""
        logger.info(f"Updating issue ID {issue_id}...")
        data = {
            "issue": {
                "notes": notes or f"Updated by API validation script on {datetime.now().isoformat()}"
            }
        }
        
        if status_id:
            data["issue"]["status_id"] = status_id
        
        try:
            self._make_request('PUT', f'issues/{issue_id}.json', data)
            logger.info(f"✅ Issue updated successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Issue update failed: {str(e)}")
            return False
    
    def create_wiki_page(self, project_id):
        """Create a wiki page for the test project"""
        wiki_title = f"TestPage{random_string(4)}"
        
        logger.info(f"Creating wiki page for project ID {project_id}...")
        data = {
            "wiki_page": {
                "title": wiki_title,
                "text": f"# {self.test_prefix} Test Wiki Page\n\nThis is a test wiki page created by the API validation script on {datetime.now().isoformat()}.\n\n* This is a bullet point\n* This is another bullet point\n\n## Subheading\n\nThis is some additional content."
            }
        }
        
        try:
            response = self._make_request('PUT', f'projects/{project_id}/wiki/{wiki_title}.json', data)
            logger.info(f"✅ Wiki page created successfully")
            self.created_resources["wiki_pages"].append({
                "project_id": project_id,
                "title": wiki_title
            })
            return response.get('wiki_page', {})
        except Exception as e:
            logger.error(f"❌ Wiki page creation failed: {str(e)}")
            return None
    
    def run_test_suite(self):
        """Run the complete test suite"""
        logger.info("Starting Redmine API functionality test suite...")
        
        # Step 1: Test connection
        if not self.test_connection():
            logger.error("Initial connection test failed, aborting test suite.")
            return False
        
        # Step 2: Get reference data
        try:
            trackers = self.get_trackers()
            if not trackers:
                logger.error("Unable to retrieve trackers, aborting test suite.")
                return False
                
            statuses = self.get_issue_statuses()
            if not statuses:
                logger.error("Unable to retrieve issue statuses, aborting test suite.")
                return False
                
            priorities = self.get_priorities()
            if not priorities:
                logger.error("Unable to retrieve priorities, aborting test suite.")
                return False
        except Exception as e:
            logger.error(f"Error retrieving reference data: {str(e)}")
            return False
        
        # Step 3: Create a test project
        project = self.create_project()
        if not project:
            logger.error("Project creation failed, aborting test suite.")
            return False
        
        project_id = project.get('id')
        
        # Step 4: Create a version for the project
        version = self.create_version(project_id)
        version_id = version.get('id') if version else None
        
        # Step 5: Create an issue in the project
        issue = self.create_issue(
            project_id, 
            tracker_id=trackers[0]['id'], 
            priority_id=priorities[0]['id'],
            version_id=version_id
        )
        
        if not issue:
            logger.error("Issue creation failed, aborting test suite.")
            return False
        
        issue_id = issue.get('id')
        
        # Step 6: Update the issue
        status_id = None
        for status in statuses:
            if status.get('name', '').lower() in ('in progress', 'assigned'):
                status_id = status['id']
                break
        
        if status_id:
            self.update_issue(issue_id, status_id, "Setting issue status to In Progress")
        else:
            self.update_issue(issue_id, notes="Adding a note to the issue")
        
        # Step 7: Create a wiki page
        wiki_page = self.create_wiki_page(project_id)
        
        logger.info("\n" + "="*50)
        logger.info(f"✅ TEST SUITE COMPLETED SUCCESSFULLY")
        logger.info("="*50)
        logger.info(f"Created project: {project.get('name')} (ID: {project_id})")
        if version:
            logger.info(f"Created version: {version.get('name')} (ID: {version_id})")
        logger.info(f"Created issue: {issue.get('subject')} (ID: {issue_id})")
        if wiki_page:
            logger.info(f"Created wiki page: {wiki_page.get('title')}")
        logger.info("="*50)
        
        return True
    
    def cleanup_resources(self):
        """Clean up all created test resources"""
        logger.info("\nCleaning up test resources...")
        
        # Delete issues
        for issue_id in self.created_resources["issues"]:
            try:
                logger.info(f"Deleting issue ID {issue_id}...")
                self._make_request('DELETE', f'issues/{issue_id}.json')
                logger.info(f"✅ Issue {issue_id} deleted")
            except Exception as e:
                logger.error(f"❌ Failed to delete issue {issue_id}: {str(e)}")
        
        # Delete wiki pages
        for wiki_page in self.created_resources["wiki_pages"]:
            try:
                project_id = wiki_page["project_id"]
                title = wiki_page["title"]
                logger.info(f"Deleting wiki page {title} from project {project_id}...")
                self._make_request('DELETE', f'projects/{project_id}/wiki/{title}.json')
                logger.info(f"✅ Wiki page {title} deleted")
            except Exception as e:
                logger.error(f"❌ Failed to delete wiki page {title}: {str(e)}")
        
        # Delete versions
        for version_id in self.created_resources["versions"]:
            try:
                logger.info(f"Deleting version ID {version_id}...")
                self._make_request('DELETE', f'versions/{version_id}.json')
                logger.info(f"✅ Version {version_id} deleted")
            except Exception as e:
                logger.error(f"❌ Failed to delete version {version_id}: {str(e)}")
        
        # Delete projects - do this last as it has dependencies
        for project_id in self.created_resources["projects"]:
            try:
                logger.info(f"Deleting project ID {project_id}...")
                self._make_request('DELETE', f'projects/{project_id}.json')
                logger.info(f"✅ Project {project_id} deleted")
            except Exception as e:
                logger.error(f"❌ Failed to delete project {project_id}: {str(e)}")
        
        logger.info("Cleanup completed")

def main():
    """Main function"""
    args = parse_args()
    
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
    
    # Create tester instance
    redmine_url = args.redmine_url
    tester = RedmineApiTester(redmine_url, api_key, args.verbose)
    
    # Run tests
    success = tester.run_test_suite()
    
    # Clean up if requested
    if args.cleanup and success:
        tester.cleanup_resources()
    elif success and not args.cleanup:
        logger.info("\nTest resources were not cleaned up. Use --cleanup to remove test data.")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())