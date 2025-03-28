"""
Redmine API integration for Redmine Extension.
This module implements the integration with the Redmine REST API.
"""

import json
import logging
import requests
from urllib.parse import urljoin

logger = logging.getLogger(__name__)

class RedmineAPI:
    """
    A wrapper for the Redmine REST API
    """
    
    def __init__(self, url, api_key):
        """
        Initialize the Redmine API client
        
        Args:
            url (str): The base URL of the Redmine instance (e.g., 'https://redmine.example.com')
            api_key (str): The API key for authentication
        """
        # Ensure URL ends with a trailing slash
        if not url.endswith('/'):
            url = url + '/'
        
        self.base_url = url
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json",
            "X-Redmine-API-Key": api_key
        }
        logger.debug(f"Redmine API client initialized with URL: {url}")
    
    def _make_request(self, method, endpoint, data=None, params=None):
        """
        Make a request to the Redmine API
        
        Args:
            method (str): HTTP method (GET, POST, PUT)
            endpoint (str): API endpoint (e.g., 'issues.json')
            data (dict, optional): Data to send in the request body
            params (dict, optional): Query parameters
            
        Returns:
            dict: The response data
        """
        url = urljoin(self.base_url, endpoint)
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers, params=params)
            elif method == 'POST':
                response = requests.post(url, headers=self.headers, json=data)
            elif method == 'PUT':
                response = requests.put(url, headers=self.headers, json=data)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            if response.status_code >= 400:
                logger.error(f"Redmine API error: {response.status_code} - {response.text}")
                raise Exception(f"API request failed with status code {response.status_code}: {response.text}")
            
            # For successful requests with no content
            if response.status_code == 204:
                return {"success": True, "message": "Operation completed successfully"}
            
            return response.json()
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Error making request to Redmine API: {str(e)}")
            raise Exception(f"Failed to communicate with Redmine API: {str(e)}")
    
    def get_issues(self, project_id=None, status_id=None, limit=25):
        """
        Get a list of issues from Redmine
        
        Args:
            project_id (str, optional): Filter by project ID
            status_id (str, optional): Filter by status ID
            limit (int, optional): Maximum number of issues to return
            
        Returns:
            list: List of issue dictionaries
        """
        params = {"limit": limit}
        
        if project_id:
            params["project_id"] = project_id
        
        if status_id:
            params["status_id"] = status_id
        
        try:
            response = self._make_request('GET', 'issues.json', params=params)
            return response.get('issues', [])
        
        except Exception as e:
            logger.error(f"Error getting issues: {str(e)}")
            raise Exception(f"Failed to get issues: {str(e)}")
    
    def get_issue(self, issue_id):
        """
        Get a specific issue from Redmine
        
        Args:
            issue_id (int): The ID of the issue to retrieve
            
        Returns:
            dict: The issue data
        """
        try:
            response = self._make_request('GET', f'issues/{issue_id}.json')
            return response.get('issue', {})
        
        except Exception as e:
            logger.error(f"Error getting issue #{issue_id}: {str(e)}")
            raise Exception(f"Failed to get issue #{issue_id}: {str(e)}")
    
    def create_issue(self, project_id, subject, description, tracker_id=None, priority_id=None, assigned_to_id=None):
        """
        Create a new issue in Redmine
        
        Args:
            project_id (str): The ID of the project where the issue will be created
            subject (str): The issue subject/title
            description (str): The issue description
            tracker_id (int, optional): The ID of the tracker (bug, feature, etc.)
            priority_id (int, optional): The ID of the priority
            assigned_to_id (int, optional): The ID of the user to assign the issue to
            
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
        if tracker_id:
            issue_data["issue"]["tracker_id"] = tracker_id
        
        if priority_id:
            issue_data["issue"]["priority_id"] = priority_id
        
        if assigned_to_id:
            issue_data["issue"]["assigned_to_id"] = assigned_to_id
        
        try:
            response = self._make_request('POST', 'issues.json', data=issue_data)
            logger.info(f"Created issue #{response.get('issue', {}).get('id')}")
            return response
        
        except Exception as e:
            logger.error(f"Error creating issue: {str(e)}")
            raise Exception(f"Failed to create issue: {str(e)}")
    
    def update_issue(self, issue_id, subject=None, description=None, tracker_id=None, 
                    priority_id=None, assigned_to_id=None, status_id=None, notes=None):
        """
        Update an existing issue in Redmine
        
        Args:
            issue_id (int): The ID of the issue to update
            subject (str, optional): The updated subject/title
            description (str, optional): The updated description
            tracker_id (int, optional): The updated tracker ID
            priority_id (int, optional): The updated priority ID
            assigned_to_id (int, optional): The updated assignee ID
            status_id (int, optional): The updated status ID
            notes (str, optional): Notes to add to the issue
            
        Returns:
            dict: Success message
        """
        issue_data = {"issue": {}}
        
        # Add fields that need to be updated
        if subject:
            issue_data["issue"]["subject"] = subject
        
        if description:
            issue_data["issue"]["description"] = description
        
        if tracker_id:
            issue_data["issue"]["tracker_id"] = tracker_id
        
        if priority_id:
            issue_data["issue"]["priority_id"] = priority_id
        
        if assigned_to_id:
            issue_data["issue"]["assigned_to_id"] = assigned_to_id
        
        if status_id:
            issue_data["issue"]["status_id"] = status_id
        
        if notes:
            issue_data["issue"]["notes"] = notes
        
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
    
    def get_projects(self):
        """
        Get a list of projects from Redmine
        
        Returns:
            list: List of project dictionaries
        """
        try:
            response = self._make_request('GET', 'projects.json')
            return response.get('projects', [])
        
        except Exception as e:
            logger.error(f"Error getting projects: {str(e)}")
            raise Exception(f"Failed to get projects: {str(e)}")
    
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