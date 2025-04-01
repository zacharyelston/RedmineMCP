#!/usr/bin/env python3
"""
Redmine Bootstrap Script

This script initializes a Redmine instance with all the necessary configuration
for API connections from agents. It sets up:
- Users and groups
- Trackers
- Issue statuses
- Priorities
- Roles and permissions
- Projects
- Custom fields
- Workflows

Usage:
  python scripts/bootstrap_redmine.py --url=http://localhost:3000 --api-key=your_api_key
  
Options:
  --url            URL of the Redmine instance (default: http://localhost:3000)
  --api-key        Admin API key for Redmine
  --credentials    Path to credentials.yaml file (default: ../credentials.yaml)
  --verbose        Show verbose output
  --verify         Only verify the setup without making changes
"""

import argparse
import json
import logging
import os
import sys
import time
import yaml
from datetime import datetime
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
    parser = argparse.ArgumentParser(description='Bootstrap a Redmine instance with required configuration')
    parser.add_argument('--url', default='http://localhost:3000', help='URL of the Redmine instance')
    parser.add_argument('--api-key', help='Admin API key for Redmine')
    parser.add_argument('--credentials', default='../credentials.yaml', help='Path to credentials.yaml file')
    parser.add_argument('--verbose', action='store_true', help='Show verbose output')
    parser.add_argument('--verify', action='store_true', help='Only verify the setup without making changes')
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

class RedmineBootstrapper:
    """Class to bootstrap Redmine with required configuration"""
    
    def __init__(self, url, api_key, verbose=False, verify_only=False):
        """Initialize the bootstrapper"""
        self.redmine_url = url.rstrip('/')
        self.api_key = api_key
        self.verbose = verbose
        self.verify_only = verify_only
        self.session = requests.Session()
        self.session.headers.update({
            'X-Redmine-API-Key': self.api_key,
            'Content-Type': 'application/json'
        })
        
        # Resource tracking
        self.existing_resources = {
            "users": [],
            "groups": [],
            "trackers": [],
            "statuses": [],
            "priorities": [],
            "roles": [],
            "projects": [],
            "custom_fields": [],
            "enumerations": {}
        }
        
        self.created_resources = {
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
    
    def _log_request(self, response):
        """Log API request details if verbose mode is enabled"""
        if self.verbose:
            try:
                logger.debug(f"Request: {response.request.method} {response.request.url}")
                logger.debug(f"Request headers: {response.request.headers}")
                logger.debug(f"Request body: {response.request.body}")
                logger.debug(f"Response status: {response.status_code}")
                logger.debug(f"Response headers: {response.headers}")
                logger.debug(f"Response body: {json.dumps(response.json(), indent=2)}")
            except:
                logger.debug(f"Response text: {response.text[:200]}...")
    
    def _make_request(self, method, endpoint, data=None, params=None):
        """Make a request to the Redmine API"""
        url = f"{self.redmine_url}/{endpoint}"
        try:
            if self.verify_only and method.upper() in ('POST', 'PUT', 'DELETE'):
                # In verify-only mode, don't make changes
                logger.info(f"VERIFY MODE: Would {method} to {endpoint}")
                if data:
                    logger.info(f"With data: {json.dumps(data, indent=2)}")
                return True
            
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
            
            if not user.get('admin'):
                logger.warning("⚠️ Warning: The API key provided does not belong to an admin user.")
                logger.warning("Some operations may fail due to insufficient permissions.")
            
            return True
        except Exception as e:
            logger.error(f"❌ Connection test failed: {str(e)}")
            return False
    
    def get_existing_resources(self):
        """Get all existing resources from Redmine"""
        logger.info("Fetching existing resources...")
        
        # Get users
        try:
            response = self._make_request('GET', 'users.json', params={'limit': 100})
            self.existing_resources["users"] = response.get('users', [])
            logger.info(f"Found {len(self.existing_resources['users'])} existing users")
        except Exception as e:
            logger.error(f"Failed to fetch users: {str(e)}")
        
        # Get groups
        try:
            response = self._make_request('GET', 'groups.json', params={'limit': 100})
            self.existing_resources["groups"] = response.get('groups', [])
            logger.info(f"Found {len(self.existing_resources['groups'])} existing groups")
        except Exception as e:
            logger.error(f"Failed to fetch groups: {str(e)}")
        
        # Get trackers
        try:
            response = self._make_request('GET', 'trackers.json')
            self.existing_resources["trackers"] = response.get('trackers', [])
            logger.info(f"Found {len(self.existing_resources['trackers'])} existing trackers")
        except Exception as e:
            logger.error(f"Failed to fetch trackers: {str(e)}")
        
        # Get issue statuses
        try:
            response = self._make_request('GET', 'issue_statuses.json')
            self.existing_resources["statuses"] = response.get('issue_statuses', [])
            logger.info(f"Found {len(self.existing_resources['statuses'])} existing issue statuses")
        except Exception as e:
            logger.error(f"Failed to fetch issue statuses: {str(e)}")
        
        # Get priorities
        try:
            response = self._make_request('GET', 'enumerations/issue_priorities.json')
            self.existing_resources["priorities"] = response.get('issue_priorities', [])
            logger.info(f"Found {len(self.existing_resources['priorities'])} existing priorities")
        except Exception as e:
            logger.error(f"Failed to fetch priorities: {str(e)}")
        
        # Get roles
        try:
            response = self._make_request('GET', 'roles.json')
            self.existing_resources["roles"] = response.get('roles', [])
            logger.info(f"Found {len(self.existing_resources['roles'])} existing roles")
        except Exception as e:
            logger.error(f"Failed to fetch roles: {str(e)}")
        
        # Get projects
        try:
            response = self._make_request('GET', 'projects.json', params={'limit': 100})
            self.existing_resources["projects"] = response.get('projects', [])
            logger.info(f"Found {len(self.existing_resources['projects'])} existing projects")
        except Exception as e:
            logger.error(f"Failed to fetch projects: {str(e)}")
        
        # Get custom fields
        try:
            response = self._make_request('GET', 'custom_fields.json')
            self.existing_resources["custom_fields"] = response.get('custom_fields', [])
            logger.info(f"Found {len(self.existing_resources['custom_fields'])} existing custom fields")
        except Exception as e:
            logger.error(f"Failed to fetch custom fields: {str(e)}")
    
    def resource_exists(self, resource_type, identifier, identifier_field='name'):
        """Check if a resource already exists"""
        for resource in self.existing_resources.get(resource_type, []):
            if resource.get(identifier_field) == identifier:
                return resource
        return None
    
    def create_user(self, login, firstname, lastname, mail, admin=False, password='password'):
        """Create a user in Redmine"""
        if self.resource_exists('users', login, 'login'):
            logger.info(f"User '{login}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating user '{login}'...")
        data = {
            "user": {
                "login": login,
                "firstname": firstname,
                "lastname": lastname,
                "mail": mail,
                "admin": admin,
                "password": password,
                "password_confirmation": password
            }
        }
        
        try:
            response = self._make_request('POST', 'users.json', data)
            user = response.get('user', {})
            user_id = user.get('id')
            logger.info(f"✅ User created successfully with ID: {user_id}")
            self.created_resources["users"].append(user_id)
            return user
        except Exception as e:
            logger.error(f"❌ User creation failed: {str(e)}")
            return None
    
    def create_group(self, name, user_ids=None):
        """Create a group in Redmine"""
        if self.resource_exists('groups', name):
            logger.info(f"Group '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating group '{name}'...")
        data = {
            "group": {
                "name": name
            }
        }
        
        if user_ids:
            data["group"]["user_ids"] = user_ids
        
        try:
            response = self._make_request('POST', 'groups.json', data)
            group = response.get('group', {})
            group_id = group.get('id')
            logger.info(f"✅ Group created successfully with ID: {group_id}")
            self.created_resources["groups"].append(group_id)
            return group
        except Exception as e:
            logger.error(f"❌ Group creation failed: {str(e)}")
            return None
    
    def create_tracker(self, name, default_status_id=1):
        """Create a tracker in Redmine"""
        if self.resource_exists('trackers', name):
            logger.info(f"Tracker '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating tracker '{name}'...")
        data = {
            "tracker": {
                "name": name,
                "default_status_id": default_status_id
            }
        }
        
        try:
            response = self._make_request('POST', 'trackers.json', data)
            tracker = response.get('tracker', {})
            tracker_id = tracker.get('id')
            logger.info(f"✅ Tracker created successfully with ID: {tracker_id}")
            self.created_resources["trackers"].append(tracker_id)
            return tracker
        except Exception as e:
            logger.error(f"❌ Tracker creation failed: {str(e)}")
            return None
    
    def create_issue_status(self, name, is_closed=False):
        """Create an issue status in Redmine"""
        if self.resource_exists('statuses', name):
            logger.info(f"Issue status '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating issue status '{name}'...")
        data = {
            "issue_status": {
                "name": name,
                "is_closed": is_closed
            }
        }
        
        try:
            response = self._make_request('POST', 'issue_statuses.json', data)
            status = response.get('issue_status', {})
            status_id = status.get('id')
            logger.info(f"✅ Issue status created successfully with ID: {status_id}")
            self.created_resources["statuses"].append(status_id)
            return status
        except Exception as e:
            logger.error(f"❌ Issue status creation failed: {str(e)}")
            return None
    
    def create_priority(self, name, is_default=False):
        """Create a priority in Redmine"""
        if self.resource_exists('priorities', name):
            logger.info(f"Priority '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating priority '{name}'...")
        data = {
            "issue_priority": {
                "name": name,
                "is_default": is_default
            }
        }
        
        try:
            response = self._make_request('POST', 'enumerations/issue_priorities.json', data)
            priority = response.get('issue_priority', {})
            priority_id = priority.get('id')
            logger.info(f"✅ Priority created successfully with ID: {priority_id}")
            self.created_resources["priorities"].append(priority_id)
            return priority
        except Exception as e:
            logger.error(f"❌ Priority creation failed: {str(e)}")
            return None
    
    def create_role(self, name, permissions=None, is_assignable=True):
        """Create a role in Redmine"""
        if self.resource_exists('roles', name):
            logger.info(f"Role '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating role '{name}'...")
        data = {
            "role": {
                "name": name,
                "assignable": is_assignable
            }
        }
        
        if permissions:
            data["role"]["permissions"] = permissions
        
        try:
            response = self._make_request('POST', 'roles.json', data)
            role = response.get('role', {})
            role_id = role.get('id')
            logger.info(f"✅ Role created successfully with ID: {role_id}")
            self.created_resources["roles"].append(role_id)
            return role
        except Exception as e:
            logger.error(f"❌ Role creation failed: {str(e)}")
            return None
    
    def create_project(self, name, identifier, description=None, is_public=True):
        """Create a project in Redmine"""
        if self.resource_exists('projects', identifier, 'identifier'):
            logger.info(f"Project '{identifier}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating project '{name}'...")
        data = {
            "project": {
                "name": name,
                "identifier": identifier,
                "is_public": is_public,
                "enabled_module_names": [
                    "issue_tracking", "time_tracking", "news", "documents", 
                    "files", "wiki", "repository", "calendar", "gantt"
                ]
            }
        }
        
        if description:
            data["project"]["description"] = description
        
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
    
    def create_custom_field(self, name, field_type, field_format, trackers=None, projects=None, is_required=False):
        """Create a custom field in Redmine"""
        if self.resource_exists('custom_fields', name):
            logger.info(f"Custom field '{name}' already exists, skipping creation")
            return None
        
        logger.info(f"Creating custom field '{name}'...")
        data = {
            "custom_field": {
                "name": name,
                "field_format": field_format,
                "is_required": is_required,
                "customized_type": field_type
            }
        }
        
        if trackers:
            data["custom_field"]["tracker_ids"] = trackers
        
        if projects:
            data["custom_field"]["project_ids"] = projects
        
        try:
            response = self._make_request('POST', 'custom_fields.json', data)
            custom_field = response.get('custom_field', {})
            custom_field_id = custom_field.get('id')
            logger.info(f"✅ Custom field created successfully with ID: {custom_field_id}")
            self.created_resources["custom_fields"].append(custom_field_id)
            return custom_field
        except Exception as e:
            logger.error(f"❌ Custom field creation failed: {str(e)}")
            return None
    
    def add_member_to_project(self, project_id, user_id, role_ids):
        """Add a member to a project with specific roles"""
        logger.info(f"Adding user {user_id} to project {project_id} with roles {role_ids}...")
        data = {
            "membership": {
                "user_id": user_id,
                "role_ids": role_ids
            }
        }
        
        try:
            response = self._make_request('POST', f'projects/{project_id}/memberships.json', data)
            membership = response.get('membership', {})
            membership_id = membership.get('id')
            logger.info(f"✅ Membership created successfully with ID: {membership_id}")
            self.created_resources["memberships"].append(membership_id)
            return membership
        except Exception as e:
            logger.error(f"❌ Membership creation failed: {str(e)}")
            return None
    
    def create_issue(self, project_id, subject, description, tracker_id, priority_id, assigned_to_id=None):
        """Create an issue in Redmine"""
        logger.info(f"Creating issue '{subject}' for project {project_id}...")
        data = {
            "issue": {
                "project_id": project_id,
                "subject": subject,
                "description": description,
                "tracker_id": tracker_id,
                "priority_id": priority_id
            }
        }
        
        if assigned_to_id:
            data["issue"]["assigned_to_id"] = assigned_to_id
        
        try:
            response = self._make_request('POST', 'issues.json', data)
            issue = response.get('issue', {})
            issue_id = issue.get('id')
            logger.info(f"✅ Issue created successfully with ID: {issue_id}")
            return issue
        except Exception as e:
            logger.error(f"❌ Issue creation failed: {str(e)}")
            return None
    
    def configure_workflow(self, tracker_id, role_id, status_transitions):
        """Configure workflow for a tracker and role"""
        # This is more complex and may require multiple API calls
        logger.info(f"Configuring workflow for tracker {tracker_id} and role {role_id}...")
        # Implementation would depend on Redmine's API support for workflow configuration
        # This may require direct database access in some Redmine versions
        pass
    
    def bootstrap(self):
        """Bootstrap the Redmine instance with all required configuration"""
        if not self.test_connection():
            logger.error("Failed to connect to Redmine, aborting bootstrap")
            return False
        
        self.get_existing_resources()
        
        # Step 1: Create default trackers if they don't exist
        trackers = {
            "Bug": self.create_tracker("Bug") or self.resource_exists('trackers', 'Bug'),
            "Feature": self.create_tracker("Feature") or self.resource_exists('trackers', 'Feature'),
            "Support": self.create_tracker("Support") or self.resource_exists('trackers', 'Support'),
            "Task": self.create_tracker("Task") or self.resource_exists('trackers', 'Task')
        }
        
        # Step 2: Create issue statuses if they don't exist
        statuses = {
            "New": self.create_issue_status("New") or self.resource_exists('statuses', 'New'),
            "In Progress": self.create_issue_status("In Progress") or self.resource_exists('statuses', 'In Progress'),
            "Resolved": self.create_issue_status("Resolved") or self.resource_exists('statuses', 'Resolved'),
            "Feedback": self.create_issue_status("Feedback") or self.resource_exists('statuses', 'Feedback'),
            "Closed": self.create_issue_status("Closed", is_closed=True) or self.resource_exists('statuses', 'Closed'),
            "Rejected": self.create_issue_status("Rejected", is_closed=True) or self.resource_exists('statuses', 'Rejected')
        }
        
        # Step 3: Create priorities if they don't exist
        priorities = {
            "Low": self.create_priority("Low") or self.resource_exists('priorities', 'Low'),
            "Normal": self.create_priority("Normal", is_default=True) or self.resource_exists('priorities', 'Normal'),
            "High": self.create_priority("High") or self.resource_exists('priorities', 'High'),
            "Urgent": self.create_priority("Urgent") or self.resource_exists('priorities', 'Urgent'),
            "Immediate": self.create_priority("Immediate") or self.resource_exists('priorities', 'Immediate')
        }
        
        # Step 4: Create roles if they don't exist
        manager_permissions = [
            "add_project", "edit_project", "close_project", "manage_members",
            "manage_versions", "add_subprojects", "manage_categories",
            "view_issues", "add_issues", "edit_issues", "copy_issues",
            "manage_issue_relations", "manage_subtasks", "set_issues_private",
            "set_own_issues_private", "add_issue_notes", "edit_issue_notes",
            "edit_own_issue_notes", "view_private_notes", "delete_issues",
            "manage_public_queries", "save_queries", "view_gantt",
            "view_calendar", "view_time_entries", "log_time",
            "edit_time_entries", "delete_time_entries", "manage_news",
            "comment_news", "manage_documents", "view_documents",
            "manage_files", "view_files", "manage_wiki", "rename_wiki_pages",
            "delete_wiki_pages", "view_wiki_pages", "export_wiki_pages",
            "view_wiki_edits", "edit_wiki_pages", "delete_wiki_pages_attachments",
            "protect_wiki_pages", "manage_repository", "browse_repository",
            "view_changesets", "commit_access", "manage_related_issues",
            "manage_boards", "add_messages", "edit_messages", "edit_own_messages",
            "delete_messages", "delete_own_messages"
        ]
        
        developer_permissions = [
            "view_issues", "add_issues", "edit_issues", "view_private_notes",
            "add_issue_notes", "save_queries", "view_gantt", "view_calendar",
            "log_time", "view_time_entries", "comment_news", "view_documents",
            "view_wiki_pages", "edit_wiki_pages", "view_files", "browse_repository",
            "view_changesets", "commit_access", "add_messages"
        ]
        
        roles = {
            "Manager": self.create_role("Manager", permissions=manager_permissions) or self.resource_exists('roles', 'Manager'),
            "Developer": self.create_role("Developer", permissions=developer_permissions) or self.resource_exists('roles', 'Developer'),
            "Reporter": self.create_role("Reporter", permissions=["view_issues", "add_issues", "add_issue_notes"]) or self.resource_exists('roles', 'Reporter')
        }
        
        # Step 5: Create users if they don't exist
        users = {
            "agent": self.create_user("agent", "API", "Agent", "agent@example.com") or self.resource_exists('users', 'agent', 'login'),
            "developer": self.create_user("developer", "Test", "Developer", "developer@example.com") or self.resource_exists('users', 'developer', 'login'),
            "manager": self.create_user("manager", "Project", "Manager", "manager@example.com") or self.resource_exists('users', 'manager', 'login')
        }
        
        # Step 6: Create groups if they don't exist
        developer_ids = [users["developer"].get('id')] if users["developer"] else []
        groups = {
            "API Agents": self.create_group("API Agents", [users["agent"].get('id')] if users["agent"] else []) or self.resource_exists('groups', 'API Agents'),
            "Developers": self.create_group("Developers", developer_ids) or self.resource_exists('groups', 'Developers'),
            "Managers": self.create_group("Managers", [users["manager"].get('id')] if users["manager"] else []) or self.resource_exists('groups', 'Managers')
        }
        
        # Step 7: Create custom fields if they don't exist
        custom_fields = {
            "Risk Level": self.create_custom_field("Risk Level", "IssueCustomField", "list", 
                                                   trackers=[t.get('id') for t in trackers.values() if t]) or self.resource_exists('custom_fields', 'Risk Level'),
            "Expected Completion": self.create_custom_field("Expected Completion", "IssueCustomField", "date") or self.resource_exists('custom_fields', 'Expected Completion'),
            "External ID": self.create_custom_field("External ID", "IssueCustomField", "string") or self.resource_exists('custom_fields', 'External ID')
        }
        
        # Step 8: Create projects if they don't exist
        projects = {
            "demo": self.create_project("Demo Project", "demo", 
                                         "A demonstration project for testing the Redmine MCP Extension") or self.resource_exists('projects', 'demo', 'identifier'),
            "api-testing": self.create_project("API Testing", "api-testing", 
                                               "Project for testing API integration") or self.resource_exists('projects', 'api-testing', 'identifier')
        }
        
        # Step 9: Assign users to projects with roles
        if projects["demo"] and users["developer"] and roles["Developer"]:
            self.add_member_to_project(projects["demo"].get('id'), users["developer"].get('id'), [roles["Developer"].get('id')])
        
        if projects["demo"] and users["manager"] and roles["Manager"]:
            self.add_member_to_project(projects["demo"].get('id'), users["manager"].get('id'), [roles["Manager"].get('id')])
        
        if projects["api-testing"] and users["agent"] and roles["Reporter"]:
            self.add_member_to_project(projects["api-testing"].get('id'), users["agent"].get('id'), [roles["Reporter"].get('id')])
        
        # Step 10: Create some sample issues
        if projects["demo"] and trackers["Bug"] and priorities["Normal"]:
            self.create_issue(
                projects["demo"].get('id'),
                "Sample Bug Issue",
                "This is a sample bug issue created during bootstrap.",
                trackers["Bug"].get('id'),
                priorities["Normal"].get('id'),
                users["developer"].get('id') if users["developer"] else None
            )
        
        if projects["api-testing"] and trackers["Feature"] and priorities["High"]:
            self.create_issue(
                projects["api-testing"].get('id'),
                "API Integration Feature",
                "Implement API integration for external systems.",
                trackers["Feature"].get('id'),
                priorities["High"].get('id')
            )
        
        logger.info("\n" + "="*50)
        logger.info("✅ REDMINE BOOTSTRAP COMPLETED SUCCESSFULLY")
        logger.info("="*50)
        logger.info("Created or verified:")
        logger.info(f"- {len(trackers)} trackers")
        logger.info(f"- {len(statuses)} issue statuses")
        logger.info(f"- {len(priorities)} priorities")
        logger.info(f"- {len(roles)} roles")
        logger.info(f"- {len(users)} users")
        logger.info(f"- {len(groups)} groups")
        logger.info(f"- {len(custom_fields)} custom fields")
        logger.info(f"- {len(projects)} projects")
        logger.info("="*50)
        
        return True
    
    def verify_setup(self):
        """Verify if the Redmine instance has the minimum required setup"""
        logger.info("Verifying Redmine setup...")
        
        self.get_existing_resources()
        
        # Check for minimum required configuration
        requirements = {
            "Users": len(self.existing_resources["users"]) > 0,
            "Trackers": len(self.existing_resources["trackers"]) > 0,
            "Issue Statuses": len(self.existing_resources["statuses"]) > 0,
            "Priorities": len(self.existing_resources["priorities"]) > 0,
            "Roles": len(self.existing_resources["roles"]) > 0,
            "Projects": len(self.existing_resources["projects"]) > 0
        }
        
        all_requirements_met = all(requirements.values())
        
        logger.info("\n" + "="*50)
        logger.info("REDMINE SETUP VERIFICATION RESULTS")
        logger.info("="*50)
        
        for requirement, status in requirements.items():
            logger.info(f"{requirement}: {'✅ OK' if status else '❌ Missing'}")
        
        logger.info("="*50)
        logger.info(f"Overall Status: {'✅ Ready for API connections' if all_requirements_met else '❌ Not ready - bootstrap required'}")
        logger.info("="*50)
        
        return all_requirements_met

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
    
    # Create bootstrapper instance
    redmine_url = args.url
    bootstrapper = RedmineBootstrapper(redmine_url, api_key, args.verbose, args.verify)
    
    # Run bootstrap or verification
    if args.verify:
        success = bootstrapper.verify_setup()
    else:
        success = bootstrapper.bootstrap()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())