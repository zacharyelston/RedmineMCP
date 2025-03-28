import requests
import logging

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
        self.url = url.rstrip('/')  # Remove trailing slash if present
        self.api_key = api_key
        self.headers = {
            'X-Redmine-API-Key': self.api_key,
            'Content-Type': 'application/json'
        }
    
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
        params = {'limit': limit}
        if project_id:
            params['project_id'] = project_id
        if status_id:
            params['status_id'] = status_id
        
        response = requests.get(
            f"{self.url}/issues.json",
            headers=self.headers,
            params=params
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching issues: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['issues']
    
    def get_issue(self, issue_id):
        """
        Get a specific issue from Redmine
        
        Args:
            issue_id (int): The ID of the issue to retrieve
            
        Returns:
            dict: The issue data
        """
        response = requests.get(
            f"{self.url}/issues/{issue_id}.json",
            headers=self.headers,
            params={'include': 'journals,attachments,relations,children,watchers'}
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching issue {issue_id}: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['issue']
    
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
            'issue': {
                'project_id': project_id,
                'subject': subject,
                'description': description
            }
        }
        
        # Add optional parameters if provided
        if tracker_id:
            issue_data['issue']['tracker_id'] = tracker_id
        if priority_id:
            issue_data['issue']['priority_id'] = priority_id
        if assigned_to_id:
            issue_data['issue']['assigned_to_id'] = assigned_to_id
        
        response = requests.post(
            f"{self.url}/issues.json",
            headers=self.headers,
            json=issue_data
        )
        
        if response.status_code not in (201, 200):
            error_msg = f"Error creating issue: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['issue']
    
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
        issue_data = {'issue': {}}
        
        # Only include fields that are provided
        if subject:
            issue_data['issue']['subject'] = subject
        if description:
            issue_data['issue']['description'] = description
        if tracker_id:
            issue_data['issue']['tracker_id'] = tracker_id
        if priority_id:
            issue_data['issue']['priority_id'] = priority_id
        if assigned_to_id:
            issue_data['issue']['assigned_to_id'] = assigned_to_id
        if status_id:
            issue_data['issue']['status_id'] = status_id
        if notes:
            issue_data['issue']['notes'] = notes
        
        # If no updates provided, return early
        if not issue_data['issue']:
            return {"message": "No updates provided"}
        
        response = requests.put(
            f"{self.url}/issues/{issue_id}.json",
            headers=self.headers,
            json=issue_data
        )
        
        if response.status_code != 204:  # Redmine returns 204 No Content on successful update
            error_msg = f"Error updating issue {issue_id}: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return {"message": f"Issue {issue_id} updated successfully"}
    
    def get_projects(self):
        """
        Get a list of projects from Redmine
        
        Returns:
            list: List of project dictionaries
        """
        response = requests.get(
            f"{self.url}/projects.json",
            headers=self.headers
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching projects: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['projects']
    
    def get_trackers(self):
        """
        Get a list of trackers from Redmine
        
        Returns:
            list: List of tracker dictionaries
        """
        response = requests.get(
            f"{self.url}/trackers.json",
            headers=self.headers
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching trackers: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['trackers']
    
    def get_statuses(self):
        """
        Get a list of issue statuses from Redmine
        
        Returns:
            list: List of status dictionaries
        """
        response = requests.get(
            f"{self.url}/issue_statuses.json",
            headers=self.headers
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching issue statuses: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['issue_statuses']
    
    def get_priorities(self):
        """
        Get a list of issue priorities from Redmine
        
        Returns:
            list: List of priority dictionaries
        """
        response = requests.get(
            f"{self.url}/enumerations/issue_priorities.json",
            headers=self.headers
        )
        
        if response.status_code != 200:
            error_msg = f"Error fetching issue priorities: {response.status_code} - {response.text}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        return response.json()['issue_priorities']
