"""
Redmine API integration for Redmine Extension.
This module implements the integration with the Redmine REST API.
Uses file-based configuration instead of database.
"""

import json
import logging
import requests
import os
from urllib.parse import urljoin
from config import get_config

logger = logging.getLogger(__name__)

def create_redmine_client():
    """
    Create a Redmine API client using file-based configuration
    
    Returns:
        RedmineAPI: An instance of the Redmine API client
    """
    # Get configuration from file
    config = get_config()
    redmine_url = config.get('redmine_url')
    redmine_api_key = config.get('redmine_api_key')
    
    if not redmine_url or not redmine_api_key:
        logger.error("Redmine URL or API key not found in configuration")
        
        # Check if we have default values in the manifest for fallback
        redmine_defaults = config.get('redmine_defaults', {})
        if redmine_defaults:
            # Use manifest defaults to construct a URL if possible
            host = redmine_defaults.get('default_host')
            port = redmine_defaults.get('default_port')
            protocol = redmine_defaults.get('default_protocol', 'http')
            
            if host and port:
                redmine_url = f"{protocol}://{host}:{port}/"
                logger.warning(f"Using default Redmine URL from manifest: {redmine_url}")
                logger.warning("API key still required for full functionality")
                # Continue with limited functionality (no API key)
                return RedmineAPI(redmine_url, None)
        
        # If we still don't have a URL, raise an error
        if not redmine_url:
            raise ValueError("Missing Redmine configuration. Please check credentials.yaml")
    
    return RedmineAPI(redmine_url, redmine_api_key)

class RedmineAPI:
    """
    A wrapper for the Redmine REST API
    """
    
    def __init__(self, url, api_key):
        """
        Initialize the Redmine API client
        
        Args:
            url (str): The base URL of the Redmine instance (e.g., 'https://redmine.example.com')
            api_key (str): The API key for authentication (can be None for limited functionality)
        """
        # Ensure URL ends with a trailing slash
        if not url.endswith('/'):
            url = url + '/'
        
        self.base_url = url
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json"
        }
        
        # Only add API key header if one is provided
        if api_key:
            self.headers["X-Redmine-API-Key"] = api_key
            logger.debug(f"Redmine API client initialized with URL: {url}")
        else:
            logger.warning(f"Redmine API client initialized with URL: {url} but WITHOUT API key (limited functionality)")
            self.limited_mode = True
    
    def _make_request(self, method, endpoint, data=None, params=None, files=None):
        """
        Make a request to the Redmine API
        
        Args:
            method (str): HTTP method (GET, POST, PUT, DELETE)
            endpoint (str): API endpoint (e.g., 'issues.json')
            data (dict, optional): Data to send in the request body
            params (dict, optional): Query parameters
            files (dict, optional): Files to upload
            
        Returns:
            dict: The response data
        """
        # Check if we're in limited mode and this is a write operation
        if hasattr(self, 'limited_mode') and self.limited_mode and method in ['POST', 'PUT', 'DELETE']:
            logger.warning(f"Cannot perform {method} operation on '{endpoint}' in limited mode - API key required")
            raise Exception(f"API key required to perform {method} operations. Please configure a valid Redmine API key.")
        
        url = urljoin(self.base_url, endpoint)
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers, params=params)
            elif method == 'POST':
                if files:
                    # For file uploads, don't send JSON
                    headers_without_content_type = {k: v for k, v in self.headers.items() if k != 'Content-Type'}
                    response = requests.post(url, headers=headers_without_content_type, data=data, files=files)
                else:
                    response = requests.post(url, headers=self.headers, json=data)
            elif method == 'PUT':
                response = requests.put(url, headers=self.headers, json=data)
            elif method == 'DELETE':
                response = requests.delete(url, headers=self.headers)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            if response.status_code >= 400:
                logger.error(f"Redmine API error: {response.status_code} - {response.text}")
                raise Exception(f"API request failed with status code {response.status_code}: {response.text}")
            
            # For successful requests with no content
            if response.status_code == 204 or not response.text.strip():
                return {"success": True, "message": "Operation completed successfully"}
            
            return response.json()
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Error making request to Redmine API: {str(e)}")
            raise Exception(f"Failed to communicate with Redmine API: {str(e)}")

    # ==========================================
    # ISSUES API
    # ==========================================
    
    def get_issues(self, project_id=None, status_id=None, tracker_id=None, 
                   assigned_to_id=None, query_id=None, limit=25, offset=0, sort=None):
        """
        Get a list of issues from Redmine with extensive filtering options
        
        Args:
            project_id (str, optional): Filter by project ID
            status_id (str, optional): Filter by status ID
            tracker_id (str, optional): Filter by tracker ID
            assigned_to_id (str, optional): Filter by assigned user ID
            query_id (str, optional): Filter by saved query ID
            limit (int, optional): Maximum number of issues to return
            offset (int, optional): Offset for pagination
            sort (str, optional): Sort field (e.g. 'updated_on:desc')
            
        Returns:
            list: List of issue dictionaries
        """
        params = {
            "limit": limit,
            "offset": offset
        }
        
        if project_id:
            params["project_id"] = project_id
        
        if status_id:
            params["status_id"] = status_id
            
        if tracker_id:
            params["tracker_id"] = tracker_id
            
        if assigned_to_id:
            params["assigned_to_id"] = assigned_to_id
            
        if query_id:
            params["query_id"] = query_id
            
        if sort:
            params["sort"] = sort
        
        try:
            response = self._make_request('GET', 'issues.json', params=params)
            return response.get('issues', [])
        
        except Exception as e:
            logger.error(f"Error getting issues: {str(e)}")
            raise Exception(f"Failed to get issues: {str(e)}")
    
    def get_issue(self, issue_id, include=None):
        """
        Get a specific issue from Redmine with option to include associated data
        
        Args:
            issue_id (int): The ID of the issue to retrieve
            include (list, optional): List of associations to include (e.g., ['attachments', 'journals'])
            
        Returns:
            dict: The issue data
        """
        params = {}
        if include:
            if isinstance(include, list):
                include_str = ",".join(include)
                params.update({"include": include_str})
            else:
                include_str = str(include)
                params.update({"include": include_str})
        
        try:
            response = self._make_request('GET', f'issues/{issue_id}.json', params=params)
            return response.get('issue', {})
        
        except Exception as e:
            logger.error(f"Error getting issue #{issue_id}: {str(e)}")
            raise Exception(f"Failed to get issue #{issue_id}: {str(e)}")
    
    def create_issue(self, project_id, subject, description, tracker_id=None, priority_id=None, 
                     assigned_to_id=None, status_id=None, category_id=None, fixed_version_id=None,
                     parent_issue_id=None, start_date=None, due_date=None, estimated_hours=None,
                     done_ratio=None, custom_fields=None, uploads=None, watcher_user_ids=None):
        """
        Create a new issue in Redmine with comprehensive options
        
        Args:
            project_id (str): The ID of the project where the issue will be created
            subject (str): The issue subject/title
            description (str): The issue description
            tracker_id (int, optional): The ID of the tracker (bug, feature, etc.)
            priority_id (int, optional): The ID of the priority
            assigned_to_id (int, optional): The ID of the user to assign the issue to
            status_id (int, optional): The ID of the status
            category_id (int, optional): The ID of the category
            fixed_version_id (int, optional): The ID of the version
            parent_issue_id (int, optional): The ID of the parent issue
            start_date (str, optional): Start date in format YYYY-MM-DD
            due_date (str, optional): Due date in format YYYY-MM-DD
            estimated_hours (float, optional): Estimated hours
            done_ratio (int, optional): Completion percentage (0-100)
            custom_fields (list, optional): List of custom field values
            uploads (list, optional): List of previously uploaded files to attach
            watcher_user_ids (list, optional): List of user IDs to add as watchers
            
        Returns:
            dict: The created issue data
        """
        issue_data = {
            "issue": {
                "project_id": project_id,
                "subject": subject,
                "description": description
            }
        }
        
        # Add optional fields if provided
        optional_fields = {
            "tracker_id": tracker_id,
            "priority_id": priority_id,
            "assigned_to_id": assigned_to_id,
            "status_id": status_id,
            "category_id": category_id,
            "fixed_version_id": fixed_version_id,
            "parent_issue_id": parent_issue_id,
            "start_date": start_date,
            "due_date": due_date,
            "estimated_hours": estimated_hours,
            "done_ratio": done_ratio
        }
        
        for field, value in optional_fields.items():
            if value is not None:
                issue_data["issue"][field] = value
        
        # Add custom fields if provided
        if custom_fields:
            issue_data["issue"]["custom_fields"] = custom_fields
        
        # Add uploads if provided
        if uploads:
            issue_data["issue"]["uploads"] = uploads
            
        # Add watchers if provided
        if watcher_user_ids:
            issue_data["issue"]["watcher_user_ids"] = watcher_user_ids
        
        try:
            response = self._make_request('POST', 'issues.json', data=issue_data)
            logger.info(f"Created issue #{response.get('issue', {}).get('id')}")
            return response
        
        except Exception as e:
            logger.error(f"Error creating issue: {str(e)}")
            raise Exception(f"Failed to create issue: {str(e)}")
    
    def update_issue(self, issue_id, subject=None, description=None, tracker_id=None, 
                    priority_id=None, assigned_to_id=None, status_id=None, category_id=None, 
                    fixed_version_id=None, parent_issue_id=None, start_date=None, due_date=None, 
                    estimated_hours=None, done_ratio=None, notes=None, custom_fields=None, 
                    uploads=None, private_notes=False):
        """
        Update an existing issue in Redmine with comprehensive options
        
        Args:
            issue_id (int): The ID of the issue to update
            subject (str, optional): The updated subject/title
            description (str, optional): The updated description
            tracker_id (int, optional): The updated tracker ID
            priority_id (int, optional): The updated priority ID
            assigned_to_id (int, optional): The updated assignee ID
            status_id (int, optional): The updated status ID
            category_id (int, optional): The updated category ID
            fixed_version_id (int, optional): The updated version ID
            parent_issue_id (int, optional): The updated parent issue ID
            start_date (str, optional): Updated start date in format YYYY-MM-DD
            due_date (str, optional): Updated due date in format YYYY-MM-DD
            estimated_hours (float, optional): Updated estimated hours
            done_ratio (int, optional): Updated completion percentage (0-100)
            notes (str, optional): Notes to add to the issue
            custom_fields (list, optional): Updated custom field values
            uploads (list, optional): List of previously uploaded files to attach
            private_notes (bool, optional): Whether notes should be private
            
        Returns:
            dict: Success message
        """
        issue_data = {"issue": {}}
        
        # Add fields that need to be updated
        optional_fields = {
            "subject": subject,
            "description": description,
            "tracker_id": tracker_id,
            "priority_id": priority_id,
            "assigned_to_id": assigned_to_id,
            "status_id": status_id,
            "category_id": category_id,
            "fixed_version_id": fixed_version_id,
            "parent_issue_id": parent_issue_id,
            "start_date": start_date,
            "due_date": due_date,
            "estimated_hours": estimated_hours,
            "done_ratio": done_ratio,
            "notes": notes
        }
        
        for field, value in optional_fields.items():
            if value is not None:
                issue_data["issue"][field] = value
        
        # Add custom fields if provided
        if custom_fields:
            issue_data["issue"]["custom_fields"] = custom_fields
        
        # Add private notes flag if notes are provided
        if notes and private_notes:
            issue_data["issue"]["private_notes"] = True
            
        # Add uploads if provided
        if uploads:
            issue_data["issue"]["uploads"] = uploads
        
        # Only proceed if there's something to update
        if not issue_data["issue"]:
            logger.warning(f"No updates provided for issue #{issue_id}")
            return {"success": True, "message": "No updates provided"}
        
        try:
            response = self._make_request('PUT', f'issues/{issue_id}.json', data=issue_data)
            logger.info(f"Updated issue #{issue_id}")
            return {"success": True, "message": f"Issue #{issue_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating issue #{issue_id}: {str(e)}")
            raise Exception(f"Failed to update issue #{issue_id}: {str(e)}")
    
    def delete_issue(self, issue_id):
        """
        Delete an issue from Redmine
        
        Args:
            issue_id (int): The ID of the issue to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'issues/{issue_id}.json')
            logger.info(f"Deleted issue #{issue_id}")
            return {"success": True, "message": f"Issue #{issue_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting issue #{issue_id}: {str(e)}")
            raise Exception(f"Failed to delete issue #{issue_id}: {str(e)}")
    
    # ==========================================
    # ISSUE ATTACHMENTS API
    # ==========================================
    
    def upload_file(self, file_path, file_name=None, content_type=None):
        """
        Upload a file to Redmine
        
        Args:
            file_path (str): Path to the file to upload
            file_name (str, optional): Name to use for the file (defaults to basename of file_path)
            content_type (str, optional): Content type of the file
            
        Returns:
            dict: The upload token information
        """
        if not file_name:
            file_name = os.path.basename(file_path)
            
        if not content_type:
            # Try to guess content type based on extension
            import mimetypes
            content_type, _ = mimetypes.guess_type(file_path)
            if not content_type:
                content_type = 'application/octet-stream'
        
        try:
            with open(file_path, 'rb') as file:
                files = {'file': (file_name, file, content_type)}
                response = self._make_request('POST', 'uploads.json', files=files)
                logger.info(f"Uploaded file {file_name}")
                return response.get('upload', {})
        
        except Exception as e:
            logger.error(f"Error uploading file {file_name}: {str(e)}")
            raise Exception(f"Failed to upload file {file_name}: {str(e)}")
    
    # ==========================================
    # ISSUE RELATIONS API
    # ==========================================
    
    def get_issue_relations(self, issue_id):
        """
        Get relations for a specific issue
        
        Args:
            issue_id (int): The ID of the issue
            
        Returns:
            list: List of relation dictionaries
        """
        try:
            response = self._make_request('GET', f'issues/{issue_id}/relations.json')
            return response.get('relations', [])
        
        except Exception as e:
            logger.error(f"Error getting relations for issue #{issue_id}: {str(e)}")
            raise Exception(f"Failed to get relations for issue #{issue_id}: {str(e)}")
    
    def create_issue_relation(self, issue_id, relation_type, issue_to_id, delay=None):
        """
        Create a relation between two issues
        
        Args:
            issue_id (int): The ID of the first issue
            relation_type (str): The type of relation (e.g., 'relates', 'blocks', 'precedes')
            issue_to_id (int): The ID of the second issue
            delay (int, optional): Delay in days for precedes/follows relations
            
        Returns:
            dict: The created relation data
        """
        relation_data = {
            "relation": {
                "relation_type": relation_type,
                "issue_to_id": issue_to_id
            }
        }
        
        if delay is not None and relation_type in ['precedes', 'follows']:
            relation_data["relation"]["delay"] = delay
        
        try:
            response = self._make_request('POST', f'issues/{issue_id}/relations.json', data=relation_data)
            logger.info(f"Created relation between issues #{issue_id} and #{issue_to_id}")
            return response.get('relation', {})
        
        except Exception as e:
            logger.error(f"Error creating relation between issues #{issue_id} and #{issue_to_id}: {str(e)}")
            raise Exception(f"Failed to create relation between issues #{issue_id} and #{issue_to_id}: {str(e)}")
    
    def delete_issue_relation(self, relation_id):
        """
        Delete an issue relation
        
        Args:
            relation_id (int): The ID of the relation to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'relations/{relation_id}.json')
            logger.info(f"Deleted relation #{relation_id}")
            return {"success": True, "message": f"Relation #{relation_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting relation #{relation_id}: {str(e)}")
            raise Exception(f"Failed to delete relation #{relation_id}: {str(e)}")
    
    # ==========================================
    # PROJECTS API
    # ==========================================
    
    def get_projects(self, limit=25, offset=0, include=None):
        """
        Get a list of projects from Redmine with option to include associated data
        
        Args:
            limit (int, optional): Maximum number of projects to return
            offset (int, optional): Offset for pagination
            include (list, optional): List of associations to include
            
        Returns:
            list: List of project dictionaries
        """
        params = {}
        
        # Add limit and offset as integers
        if limit is not None:
            params["limit"] = int(limit)
        if offset is not None:
            params["offset"] = int(offset)
        
        # Handle include parameter properly
        if include:
            if isinstance(include, list):
                include_str = ",".join(include)
                params.update({"include": include_str})
            else:
                include_str = str(include)
                params.update({"include": include_str})
        
        try:
            response = self._make_request('GET', 'projects.json', params=params)
            return response.get('projects', [])
        
        except Exception as e:
            logger.error(f"Error getting projects: {str(e)}")
            raise Exception(f"Failed to get projects: {str(e)}")
    
    def get_project(self, project_id, include=None):
        """
        Get a specific project from Redmine
        
        Args:
            project_id (str): The ID or identifier of the project
            include (list, optional): List of associations to include
            
        Returns:
            dict: The project data
        """
        params = {}
        if include:
            if isinstance(include, list):
                include_str = ",".join(include)
                params.update({"include": include_str})
            else:
                include_str = str(include)
                params.update({"include": include_str})
        
        try:
            response = self._make_request('GET', f'projects/{project_id}.json', params=params)
            return response.get('project', {})
        
        except Exception as e:
            logger.error(f"Error getting project {project_id}: {str(e)}")
            raise Exception(f"Failed to get project {project_id}: {str(e)}")
    
    def create_project(self, name, identifier, description=None, homepage=None, is_public=True, 
                      parent_id=None, inherit_members=False, tracker_ids=None, custom_field_values=None):
        """
        Create a new project in Redmine
        
        Args:
            name (str): The name of the project
            identifier (str): The identifier of the project (used in URLs)
            description (str, optional): The description of the project
            homepage (str, optional): The homepage URL of the project
            is_public (bool, optional): Whether the project is public
            parent_id (int, optional): The ID of the parent project
            inherit_members (bool, optional): Whether to inherit members from parent project
            tracker_ids (list, optional): List of tracker IDs enabled for this project
            custom_field_values (dict, optional): Custom field values
            
        Returns:
            dict: The created project data
        """
        project_data = {
            "project": {
                "name": name,
                "identifier": identifier,
                "is_public": is_public,
                "inherit_members": inherit_members
            }
        }
        
        if description:
            project_data["project"]["description"] = description
            
        if homepage:
            project_data["project"]["homepage"] = homepage
            
        if parent_id:
            project_data["project"]["parent_id"] = parent_id
            
        if tracker_ids:
            project_data["project"]["tracker_ids"] = tracker_ids
            
        if custom_field_values:
            project_data["project"]["custom_fields"] = []
            for id, value in custom_field_values.items():
                project_data["project"]["custom_fields"].append({
                    "id": id,
                    "value": value
                })
        
        try:
            response = self._make_request('POST', 'projects.json', data=project_data)
            logger.info(f"Created project {identifier}")
            return response.get('project', {})
        
        except Exception as e:
            logger.error(f"Error creating project {name}: {str(e)}")
            raise Exception(f"Failed to create project {name}: {str(e)}")
    
    def update_project(self, project_id, name=None, description=None, homepage=None, is_public=None, 
                      parent_id=None, inherit_members=None, tracker_ids=None, custom_field_values=None):
        """
        Update an existing project in Redmine
        
        Args:
            project_id (str): The ID or identifier of the project to update
            name (str, optional): The updated name of the project
            description (str, optional): The updated description of the project
            homepage (str, optional): The updated homepage URL of the project
            is_public (bool, optional): Whether the project is public
            parent_id (int, optional): The ID of the parent project
            inherit_members (bool, optional): Whether to inherit members from parent project
            tracker_ids (list, optional): Updated list of tracker IDs enabled for this project
            custom_field_values (dict, optional): Updated custom field values
            
        Returns:
            dict: Success message
        """
        project_data = {"project": {}}
        
        # Add fields that need to be updated
        if name:
            project_data["project"]["name"] = name
            
        if description is not None:
            project_data["project"]["description"] = description
            
        if homepage is not None:
            project_data["project"]["homepage"] = homepage
            
        if is_public is not None:
            project_data["project"]["is_public"] = is_public
            
        if parent_id is not None:
            project_data["project"]["parent_id"] = parent_id
            
        if inherit_members is not None:
            project_data["project"]["inherit_members"] = inherit_members
            
        if tracker_ids is not None:
            project_data["project"]["tracker_ids"] = tracker_ids
            
        if custom_field_values:
            project_data["project"]["custom_fields"] = []
            for id, value in custom_field_values.items():
                project_data["project"]["custom_fields"].append({
                    "id": id,
                    "value": value
                })
        
        # Only proceed if there's something to update
        if not project_data["project"]:
            logger.warning(f"No updates provided for project {project_id}")
            return {"success": True, "message": "No updates provided"}
        
        try:
            response = self._make_request('PUT', f'projects/{project_id}.json', data=project_data)
            logger.info(f"Updated project {project_id}")
            return {"success": True, "message": f"Project {project_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating project {project_id}: {str(e)}")
            raise Exception(f"Failed to update project {project_id}: {str(e)}")
    
    def delete_project(self, project_id):
        """
        Delete a project from Redmine
        
        Args:
            project_id (str): The ID or identifier of the project to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'projects/{project_id}.json')
            logger.info(f"Deleted project {project_id}")
            return {"success": True, "message": f"Project {project_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting project {project_id}: {str(e)}")
            raise Exception(f"Failed to delete project {project_id}: {str(e)}")
    
    # ==========================================
    # PROJECT MEMBERSHIPS API
    # ==========================================
    
    def get_project_memberships(self, project_id):
        """
        Get memberships for a specific project
        
        Args:
            project_id (str): The ID or identifier of the project
            
        Returns:
            list: List of membership dictionaries
        """
        try:
            response = self._make_request('GET', f'projects/{project_id}/memberships.json')
            return response.get('memberships', [])
        
        except Exception as e:
            logger.error(f"Error getting memberships for project {project_id}: {str(e)}")
            raise Exception(f"Failed to get memberships for project {project_id}: {str(e)}")
    
    def create_project_membership(self, project_id, user_id=None, group_id=None, role_ids=None):
        """
        Add a user or group to a project
        
        Args:
            project_id (str): The ID or identifier of the project
            user_id (int, optional): The ID of the user to add (required if group_id not provided)
            group_id (int, optional): The ID of the group to add (required if user_id not provided)
            role_ids (list): List of role IDs to assign
            
        Returns:
            dict: The created membership data
        """
        if not user_id and not group_id:
            raise ValueError("Either user_id or group_id must be provided")
            
        if not role_ids:
            raise ValueError("At least one role must be assigned (role_ids is required)")
            
        membership_data = {
            "membership": {
                "role_ids": role_ids
            }
        }
        
        if user_id:
            membership_data["membership"]["user_id"] = user_id
            
        if group_id:
            membership_data["membership"]["group_id"] = group_id
        
        try:
            response = self._make_request('POST', f'projects/{project_id}/memberships.json', data=membership_data)
            logger.info(f"Added membership to project {project_id}")
            return response.get('membership', {})
        
        except Exception as e:
            logger.error(f"Error adding membership to project {project_id}: {str(e)}")
            raise Exception(f"Failed to add membership to project {project_id}: {str(e)}")
    
    def update_project_membership(self, membership_id, role_ids):
        """
        Update the roles of a project membership
        
        Args:
            membership_id (int): The ID of the membership to update
            role_ids (list): List of role IDs to assign
            
        Returns:
            dict: Success message
        """
        membership_data = {
            "membership": {
                "role_ids": role_ids
            }
        }
        
        try:
            response = self._make_request('PUT', f'memberships/{membership_id}.json', data=membership_data)
            logger.info(f"Updated membership #{membership_id}")
            return {"success": True, "message": f"Membership #{membership_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating membership #{membership_id}: {str(e)}")
            raise Exception(f"Failed to update membership #{membership_id}: {str(e)}")
    
    def delete_project_membership(self, membership_id):
        """
        Delete a project membership
        
        Args:
            membership_id (int): The ID of the membership to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'memberships/{membership_id}.json')
            logger.info(f"Deleted membership #{membership_id}")
            return {"success": True, "message": f"Membership #{membership_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting membership #{membership_id}: {str(e)}")
            raise Exception(f"Failed to delete membership #{membership_id}: {str(e)}")
    
    # ==========================================
    # USERS API
    # ==========================================
    
    def get_users(self, status=None, name=None, group_id=None, limit=25, offset=0):
        """
        Get a list of users from Redmine with filtering options
        
        Args:
            status (int, optional): Filter by status (1=active, 3=locked)
            name (str, optional): Filter by name
            group_id (int, optional): Filter by group ID
            limit (int, optional): Maximum number of users to return
            offset (int, optional): Offset for pagination
            
        Returns:
            list: List of user dictionaries
        """
        params = {
            "limit": limit,
            "offset": offset
        }
        
        if status:
            params["status"] = status
            
        if name:
            params["name"] = name
            
        if group_id:
            params["group_id"] = group_id
        
        try:
            response = self._make_request('GET', 'users.json', params=params)
            return response.get('users', [])
        
        except Exception as e:
            logger.error(f"Error getting users: {str(e)}")
            raise Exception(f"Failed to get users: {str(e)}")
    
    def get_user(self, user_id, include=None):
        """
        Get a specific user from Redmine
        
        Args:
            user_id (int): The ID of the user to retrieve
            include (list, optional): List of associations to include (e.g., ['memberships', 'groups'])
            
        Returns:
            dict: The user data
        """
        params = {}
        if include:
            if isinstance(include, list):
                include_str = ",".join(include)
                params.update({"include": include_str})
            else:
                include_str = str(include)
                params.update({"include": include_str})
        
        try:
            response = self._make_request('GET', f'users/{user_id}.json', params=params)
            return response.get('user', {})
        
        except Exception as e:
            logger.error(f"Error getting user #{user_id}: {str(e)}")
            raise Exception(f"Failed to get user #{user_id}: {str(e)}")
    
    def create_user(self, login, password, firstname, lastname, mail, 
                  admin=False, auth_source_id=None, status=1, must_change_passwd=False):
        """
        Create a new user in Redmine
        
        Args:
            login (str): The login name of the user
            password (str): The password for the user
            firstname (str): The first name of the user
            lastname (str): The last name of the user
            mail (str): The email address of the user
            admin (bool, optional): Whether the user is an administrator
            auth_source_id (int, optional): The ID of the authentication source
            status (int, optional): The status of the user (1=active, 2=registered, 3=locked)
            must_change_passwd (bool, optional): Whether the user must change their password
            
        Returns:
            dict: The created user data
        """
        user_data = {
            "user": {
                "login": login,
                "firstname": firstname,
                "lastname": lastname,
                "mail": mail,
                "admin": admin,
                "status": status,
                "must_change_passwd": must_change_passwd
            }
        }
        
        # Add password if auth_source_id is not provided
        if not auth_source_id:
            user_data["user"]["password"] = password
        else:
            user_data["user"]["auth_source_id"] = auth_source_id
        
        try:
            response = self._make_request('POST', 'users.json', data=user_data)
            logger.info(f"Created user {login}")
            return response.get('user', {})
        
        except Exception as e:
            logger.error(f"Error creating user {login}: {str(e)}")
            raise Exception(f"Failed to create user {login}: {str(e)}")
    
    def update_user(self, user_id, login=None, firstname=None, lastname=None, mail=None, 
                  password=None, admin=None, auth_source_id=None, status=None, must_change_passwd=None):
        """
        Update an existing user in Redmine
        
        Args:
            user_id (int): The ID of the user to update
            login (str, optional): The updated login name of the user
            firstname (str, optional): The updated first name of the user
            lastname (str, optional): The updated last name of the user
            mail (str, optional): The updated email address of the user
            password (str, optional): The updated password for the user
            admin (bool, optional): Whether the user is an administrator
            auth_source_id (int, optional): The ID of the authentication source
            status (int, optional): The status of the user (1=active, 2=registered, 3=locked)
            must_change_passwd (bool, optional): Whether the user must change their password
            
        Returns:
            dict: Success message
        """
        user_data = {"user": {}}
        
        # Add fields that need to be updated
        optional_fields = {
            "login": login,
            "firstname": firstname,
            "lastname": lastname,
            "mail": mail,
            "admin": admin,
            "status": status,
            "must_change_passwd": must_change_passwd
        }
        
        for field, value in optional_fields.items():
            if value is not None:
                user_data["user"][field] = value
        
        # Add password if provided
        if password:
            user_data["user"]["password"] = password
            
        # Add auth_source_id if provided
        if auth_source_id:
            user_data["user"]["auth_source_id"] = auth_source_id
        
        # Only proceed if there's something to update
        if not user_data["user"]:
            logger.warning(f"No updates provided for user #{user_id}")
            return {"success": True, "message": "No updates provided"}
        
        try:
            response = self._make_request('PUT', f'users/{user_id}.json', data=user_data)
            logger.info(f"Updated user #{user_id}")
            return {"success": True, "message": f"User #{user_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating user #{user_id}: {str(e)}")
            raise Exception(f"Failed to update user #{user_id}: {str(e)}")
    
    def delete_user(self, user_id):
        """
        Delete a user from Redmine
        
        Args:
            user_id (int): The ID of the user to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'users/{user_id}.json')
            logger.info(f"Deleted user #{user_id}")
            return {"success": True, "message": f"User #{user_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting user #{user_id}: {str(e)}")
            raise Exception(f"Failed to delete user #{user_id}: {str(e)}")
    
    # ==========================================
    # TIME ENTRIES API
    # ==========================================
    
    def get_time_entries(self, user_id=None, project_id=None, issue_id=None, 
                        spent_on=None, from_date=None, to_date=None, limit=25, offset=0):
        """
        Get a list of time entries from Redmine with filtering options
        
        Args:
            user_id (int, optional): Filter by user ID
            project_id (str, optional): Filter by project ID
            issue_id (int, optional): Filter by issue ID
            spent_on (str, optional): Filter by date (YYYY-MM-DD)
            from_date (str, optional): Filter by start date (YYYY-MM-DD)
            to_date (str, optional): Filter by end date (YYYY-MM-DD)
            limit (int, optional): Maximum number of entries to return
            offset (int, optional): Offset for pagination
            
        Returns:
            list: List of time entry dictionaries
        """
        params = {
            "limit": limit,
            "offset": offset
        }
        
        if user_id:
            params["user_id"] = user_id
            
        if project_id:
            params["project_id"] = project_id
            
        if issue_id:
            params["issue_id"] = issue_id
            
        if spent_on:
            params["spent_on"] = spent_on
            
        if from_date:
            params["from"] = from_date
            
        if to_date:
            params["to"] = to_date
        
        try:
            response = self._make_request('GET', 'time_entries.json', params=params)
            return response.get('time_entries', [])
        
        except Exception as e:
            logger.error(f"Error getting time entries: {str(e)}")
            raise Exception(f"Failed to get time entries: {str(e)}")
    
    def get_time_entry(self, time_entry_id):
        """
        Get a specific time entry from Redmine
        
        Args:
            time_entry_id (int): The ID of the time entry to retrieve
            
        Returns:
            dict: The time entry data
        """
        try:
            response = self._make_request('GET', f'time_entries/{time_entry_id}.json')
            return response.get('time_entry', {})
        
        except Exception as e:
            logger.error(f"Error getting time entry #{time_entry_id}: {str(e)}")
            raise Exception(f"Failed to get time entry #{time_entry_id}: {str(e)}")
    
    def create_time_entry(self, issue_id=None, project_id=None, spent_on=None, 
                        hours=None, activity_id=None, comments=None, custom_fields=None):
        """
        Create a new time entry in Redmine
        
        Args:
            issue_id (int, optional): The ID of the issue (required if project_id not provided)
            project_id (str, optional): The ID of the project (required if issue_id not provided)
            spent_on (str, optional): The date when time was spent (YYYY-MM-DD)
            hours (float): The number of hours spent
            activity_id (int, optional): The ID of the time activity
            comments (str, optional): Comments about the time spent
            custom_fields (list, optional): List of custom field values
            
        Returns:
            dict: The created time entry data
        """
        if not issue_id and not project_id:
            raise ValueError("Either issue_id or project_id must be provided")
            
        if hours is None:
            raise ValueError("Hours must be provided")
            
        time_entry_data = {
            "time_entry": {
                "hours": hours
            }
        }
        
        if issue_id:
            time_entry_data["time_entry"]["issue_id"] = issue_id
            
        if project_id:
            time_entry_data["time_entry"]["project_id"] = project_id
            
        if spent_on:
            time_entry_data["time_entry"]["spent_on"] = spent_on
            
        if activity_id:
            time_entry_data["time_entry"]["activity_id"] = activity_id
            
        if comments:
            time_entry_data["time_entry"]["comments"] = comments
            
        if custom_fields:
            time_entry_data["time_entry"]["custom_fields"] = custom_fields
        
        try:
            response = self._make_request('POST', 'time_entries.json', data=time_entry_data)
            logger.info(f"Created time entry #{response.get('time_entry', {}).get('id')}")
            return response.get('time_entry', {})
        
        except Exception as e:
            logger.error(f"Error creating time entry: {str(e)}")
            raise Exception(f"Failed to create time entry: {str(e)}")
    
    def update_time_entry(self, time_entry_id, issue_id=None, project_id=None, spent_on=None, 
                        hours=None, activity_id=None, comments=None, custom_fields=None):
        """
        Update an existing time entry in Redmine
        
        Args:
            time_entry_id (int): The ID of the time entry to update
            issue_id (int, optional): The updated ID of the issue
            project_id (str, optional): The updated ID of the project
            spent_on (str, optional): The updated date when time was spent (YYYY-MM-DD)
            hours (float, optional): The updated number of hours spent
            activity_id (int, optional): The updated ID of the time activity
            comments (str, optional): Updated comments about the time spent
            custom_fields (list, optional): Updated list of custom field values
            
        Returns:
            dict: Success message
        """
        time_entry_data = {"time_entry": {}}
        
        # Add fields that need to be updated
        if issue_id:
            time_entry_data["time_entry"]["issue_id"] = issue_id
            
        if project_id:
            time_entry_data["time_entry"]["project_id"] = project_id
            
        if spent_on:
            time_entry_data["time_entry"]["spent_on"] = spent_on
            
        if hours is not None:
            time_entry_data["time_entry"]["hours"] = hours
            
        if activity_id:
            time_entry_data["time_entry"]["activity_id"] = activity_id
            
        if comments is not None:
            time_entry_data["time_entry"]["comments"] = comments
            
        if custom_fields:
            time_entry_data["time_entry"]["custom_fields"] = custom_fields
        
        # Only proceed if there's something to update
        if not time_entry_data["time_entry"]:
            logger.warning(f"No updates provided for time entry #{time_entry_id}")
            return {"success": True, "message": "No updates provided"}
        
        try:
            response = self._make_request('PUT', f'time_entries/{time_entry_id}.json', data=time_entry_data)
            logger.info(f"Updated time entry #{time_entry_id}")
            return {"success": True, "message": f"Time entry #{time_entry_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating time entry #{time_entry_id}: {str(e)}")
            raise Exception(f"Failed to update time entry #{time_entry_id}: {str(e)}")
    
    def delete_time_entry(self, time_entry_id):
        """
        Delete a time entry from Redmine
        
        Args:
            time_entry_id (int): The ID of the time entry to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'time_entries/{time_entry_id}.json')
            logger.info(f"Deleted time entry #{time_entry_id}")
            return {"success": True, "message": f"Time entry #{time_entry_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting time entry #{time_entry_id}: {str(e)}")
            raise Exception(f"Failed to delete time entry #{time_entry_id}: {str(e)}")
    
    # ==========================================
    # PROJECT VERSIONS API
    # ==========================================
    
    def get_project_versions(self, project_id):
        """
        Get versions for a specific project
        
        Args:
            project_id (str): The ID or identifier of the project
            
        Returns:
            list: List of version dictionaries
        """
        try:
            response = self._make_request('GET', f'projects/{project_id}/versions.json')
            return response.get('versions', [])
        
        except Exception as e:
            logger.error(f"Error getting versions for project {project_id}: {str(e)}")
            raise Exception(f"Failed to get versions for project {project_id}: {str(e)}")
    
    def get_version(self, version_id):
        """
        Get a specific version from Redmine
        
        Args:
            version_id (int): The ID of the version to retrieve
            
        Returns:
            dict: The version data
        """
        try:
            response = self._make_request('GET', f'versions/{version_id}.json')
            return response.get('version', {})
        
        except Exception as e:
            logger.error(f"Error getting version #{version_id}: {str(e)}")
            raise Exception(f"Failed to get version #{version_id}: {str(e)}")
    
    def create_version(self, project_id, name, status='open', sharing='none', 
                     description=None, due_date=None, wiki_page_title=None):
        """
        Create a new version in a project
        
        Args:
            project_id (str): The ID or identifier of the project
            name (str): The name of the version
            status (str, optional): The status of the version ('open', 'locked', or 'closed')
            sharing (str, optional): The sharing mode ('none', 'descendants', 'hierarchy', 'tree', or 'system')
            description (str, optional): The description of the version
            due_date (str, optional): The due date of the version (YYYY-MM-DD)
            wiki_page_title (str, optional): The title of the wiki page describing the version
            
        Returns:
            dict: The created version data
        """
        version_data = {
            "version": {
                "project_id": project_id,
                "name": name,
                "status": status,
                "sharing": sharing
            }
        }
        
        if description:
            version_data["version"]["description"] = description
            
        if due_date:
            version_data["version"]["due_date"] = due_date
            
        if wiki_page_title:
            version_data["version"]["wiki_page_title"] = wiki_page_title
        
        try:
            response = self._make_request('POST', 'versions.json', data=version_data)
            logger.info(f"Created version {name} for project {project_id}")
            return response.get('version', {})
        
        except Exception as e:
            logger.error(f"Error creating version {name} for project {project_id}: {str(e)}")
            raise Exception(f"Failed to create version {name} for project {project_id}: {str(e)}")
    
    def update_version(self, version_id, name=None, status=None, sharing=None, 
                     description=None, due_date=None, wiki_page_title=None):
        """
        Update an existing version in Redmine
        
        Args:
            version_id (int): The ID of the version to update
            name (str, optional): The updated name of the version
            status (str, optional): The updated status of the version ('open', 'locked', or 'closed')
            sharing (str, optional): The updated sharing mode ('none', 'descendants', 'hierarchy', 'tree', or 'system')
            description (str, optional): The updated description of the version
            due_date (str, optional): The updated due date of the version (YYYY-MM-DD)
            wiki_page_title (str, optional): The updated title of the wiki page describing the version
            
        Returns:
            dict: Success message
        """
        version_data = {"version": {}}
        
        # Add fields that need to be updated
        if name:
            version_data["version"]["name"] = name
            
        if status:
            version_data["version"]["status"] = status
            
        if sharing:
            version_data["version"]["sharing"] = sharing
            
        if description is not None:
            version_data["version"]["description"] = description
            
        if due_date is not None:
            version_data["version"]["due_date"] = due_date
            
        if wiki_page_title is not None:
            version_data["version"]["wiki_page_title"] = wiki_page_title
        
        # Only proceed if there's something to update
        if not version_data["version"]:
            logger.warning(f"No updates provided for version #{version_id}")
            return {"success": True, "message": "No updates provided"}
        
        try:
            response = self._make_request('PUT', f'versions/{version_id}.json', data=version_data)
            logger.info(f"Updated version #{version_id}")
            return {"success": True, "message": f"Version #{version_id} updated successfully"}
        
        except Exception as e:
            logger.error(f"Error updating version #{version_id}: {str(e)}")
            raise Exception(f"Failed to update version #{version_id}: {str(e)}")
    
    def delete_version(self, version_id):
        """
        Delete a version from Redmine
        
        Args:
            version_id (int): The ID of the version to delete
            
        Returns:
            dict: Success message
        """
        try:
            response = self._make_request('DELETE', f'versions/{version_id}.json')
            logger.info(f"Deleted version #{version_id}")
            return {"success": True, "message": f"Version #{version_id} deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting version #{version_id}: {str(e)}")
            raise Exception(f"Failed to delete version #{version_id}: {str(e)}")
    
    # ==========================================
    # WIKI PAGES API
    # ==========================================
    
    def get_wiki_pages(self, project_id):
        """
        Get all wiki pages of a project
        
        Args:
            project_id (str): The ID or identifier of the project
            
        Returns:
            list: List of wiki page dictionaries
        """
        try:
            response = self._make_request('GET', f'projects/{project_id}/wiki/index.json')
            return response.get('wiki_pages', [])
        
        except Exception as e:
            logger.error(f"Error getting wiki pages for project {project_id}: {str(e)}")
            raise Exception(f"Failed to get wiki pages for project {project_id}: {str(e)}")
    
    def get_wiki_page(self, project_id, title, version=None):
        """
        Get a specific wiki page from a project
        
        Args:
            project_id (str): The ID or identifier of the project
            title (str): The title of the wiki page
            version (int, optional): The version of the wiki page
            
        Returns:
            dict: The wiki page data
        """
        params = {}
        if version:
            params["version"] = version
        
        try:
            endpoint = f'projects/{project_id}/wiki/{title}.json'
            response = self._make_request('GET', endpoint, params=params)
            return response.get('wiki_page', {})
        
        except Exception as e:
            logger.error(f"Error getting wiki page '{title}' for project {project_id}: {str(e)}")
            raise Exception(f"Failed to get wiki page '{title}' for project {project_id}: {str(e)}")
    
    def create_wiki_page(self, project_id, title, text, comments=None, version=None, parent_id=None):
        """
        Create or update a wiki page in a project
        
        Args:
            project_id (str): The ID or identifier of the project
            title (str): The title of the wiki page
            text (str): The content of the wiki page
            comments (str, optional): Comments about the update
            version (int, optional): The version of the wiki page
            parent_id (int, optional): The ID of the parent wiki page
            
        Returns:
            dict: The created/updated wiki page data
        """
        wiki_page_data = {
            "wiki_page": {
                "text": text
            }
        }
        
        if comments:
            wiki_page_data["wiki_page"]["comments"] = comments
            
        if version:
            wiki_page_data["wiki_page"]["version"] = version
            
        if parent_id:
            wiki_page_data["wiki_page"]["parent_id"] = parent_id
        
        try:
            endpoint = f'projects/{project_id}/wiki/{title}.json'
            response = self._make_request('PUT', endpoint, data=wiki_page_data)
            logger.info(f"Created/Updated wiki page '{title}' for project {project_id}")
            return response.get('wiki_page', {})
        
        except Exception as e:
            logger.error(f"Error creating/updating wiki page '{title}' for project {project_id}: {str(e)}")
            raise Exception(f"Failed to create/update wiki page '{title}' for project {project_id}: {str(e)}")
    
    def delete_wiki_page(self, project_id, title):
        """
        Delete a wiki page from a project
        
        Args:
            project_id (str): The ID or identifier of the project
            title (str): The title of the wiki page to delete
            
        Returns:
            dict: Success message
        """
        try:
            endpoint = f'projects/{project_id}/wiki/{title}.json'
            response = self._make_request('DELETE', endpoint)
            logger.info(f"Deleted wiki page '{title}' from project {project_id}")
            return {"success": True, "message": f"Wiki page '{title}' deleted successfully"}
        
        except Exception as e:
            logger.error(f"Error deleting wiki page '{title}' from project {project_id}: {str(e)}")
            raise Exception(f"Failed to delete wiki page '{title}' from project {project_id}: {str(e)}")
    
    # ==========================================
    # METADATA & UTILITIES
    # ==========================================
    
    def get_trackers(self):
        """
        Get a list of trackers from Redmine
        
        Returns:
            list: List of tracker dictionaries
        """
        try:
            response = self._make_request('GET', 'trackers.json')
            return response.get('trackers', [])
        
        except Exception as e:
            logger.error(f"Error getting trackers: {str(e)}")
            raise Exception(f"Failed to get trackers: {str(e)}")
    
    def get_statuses(self):
        """
        Get a list of issue statuses from Redmine
        
        Returns:
            list: List of status dictionaries
        """
        try:
            response = self._make_request('GET', 'issue_statuses.json')
            return response.get('issue_statuses', [])
        
        except Exception as e:
            logger.error(f"Error getting statuses: {str(e)}")
            raise Exception(f"Failed to get statuses: {str(e)}")
    
    def get_priorities(self):
        """
        Get a list of issue priorities from Redmine
        
        Returns:
            list: List of priority dictionaries
        """
        try:
            response = self._make_request('GET', 'enumerations/issue_priorities.json')
            return response.get('issue_priorities', [])
        
        except Exception as e:
            logger.error(f"Error getting priorities: {str(e)}")
            raise Exception(f"Failed to get priorities: {str(e)}")
            
    def get_roles(self):
        """
        Get a list of roles from Redmine
        
        Returns:
            list: List of role dictionaries
        """
        try:
            response = self._make_request('GET', 'roles.json')
            return response.get('roles', [])
        
        except Exception as e:
            logger.error(f"Error getting roles: {str(e)}")
            raise Exception(f"Failed to get roles: {str(e)}")
            
    def get_time_entry_activities(self):
        """
        Get a list of time entry activities from Redmine
        
        Returns:
            list: List of time entry activity dictionaries
        """
        try:
            response = self._make_request('GET', 'enumerations/time_entry_activities.json')
            return response.get('time_entry_activities', [])
        
        except Exception as e:
            logger.error(f"Error getting time entry activities: {str(e)}")
            raise Exception(f"Failed to get time entry activities: {str(e)}")
            
    def get_issue_categories(self, project_id):
        """
        Get a list of issue categories for a project
        
        Args:
            project_id (str): The ID or identifier of the project
            
        Returns:
            list: List of issue category dictionaries
        """
        try:
            response = self._make_request('GET', f'projects/{project_id}/issue_categories.json')
            return response.get('issue_categories', [])
        
        except Exception as e:
            logger.error(f"Error getting issue categories for project {project_id}: {str(e)}")
            raise Exception(f"Failed to get issue categories for project {project_id}: {str(e)}")
            
    def get_custom_fields(self):
        """
        Get a list of custom fields from Redmine
        
        Returns:
            list: List of custom field dictionaries
        """
        try:
            response = self._make_request('GET', 'custom_fields.json')
            return response.get('custom_fields', [])
        
        except Exception as e:
            logger.error(f"Error getting custom fields: {str(e)}")
            raise Exception(f"Failed to get custom fields: {str(e)}")