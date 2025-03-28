import json
import os
import logging
# the newest OpenAI model is "gpt-4o" which was released May 13, 2024.
# do not change this unless explicitly requested by the user
from openai import OpenAI

logger = logging.getLogger(__name__)

class LLMAPI:
    """
    A wrapper for the OpenAI API to handle LLM tasks
    """
    
    def __init__(self, api_key):
        """
        Initialize the OpenAI API client
        
        Args:
            api_key (str): The OpenAI API key
        """
        self.client = OpenAI(api_key=api_key)
    
    def generate_issue(self, prompt):
        """
        Generate Redmine issue attributes based on a prompt
        
        Args:
            prompt (str): The user's prompt describing the issue
            
        Returns:
            dict: The generated issue attributes
        """
        system_prompt = """
        You are a helpful assistant that creates well-structured Redmine issues from user descriptions.
        
        Generate a JSON object with the following fields:
        - project_id: The numeric ID of the project (if mentioned, otherwise null)
        - subject: A clear, concise title for the issue (required)
        - description: A detailed description of the issue, including steps to reproduce if applicable (required)
        - tracker_id: The numeric ID of the tracker (e.g., 1 for bug, 2 for feature) if mentioned, otherwise null
        - priority_id: The numeric ID of the priority (e.g., 1 for low, 2 for normal, 3 for high) if mentioned, otherwise null
        - assigned_to_id: The numeric ID of the assignee if mentioned, otherwise null
        
        Format your response as a valid JSON object.
        """
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"}
            )
            
            issue_data = json.loads(response.choices[0].message.content)
            
            # Ensure required fields are present
            if 'subject' not in issue_data or not issue_data['subject']:
                raise ValueError("Generated issue is missing a subject")
            if 'description' not in issue_data or not issue_data['description']:
                raise ValueError("Generated issue is missing a description")
            
            return issue_data
        except Exception as e:
            error_msg = f"Error generating issue: {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)
    
    def update_issue(self, prompt, current_issue):
        """
        Generate updated Redmine issue attributes based on a prompt and current issue
        
        Args:
            prompt (str): The user's prompt describing the desired updates
            current_issue (dict): The current issue data from Redmine
            
        Returns:
            dict: The updated issue attributes
        """
        system_prompt = """
        You are a helpful assistant that updates Redmine issues based on user instructions.
        
        You will be provided with the current state of an issue and a request for changes.
        Generate a JSON object with only the fields that should be updated:
        - subject: The updated title (only if it should change)
        - description: The updated description (only if it should change)
        - tracker_id: The updated tracker ID (only if it should change)
        - priority_id: The updated priority ID (only if it should change)
        - status_id: The updated status ID (only if it should change)
        - assigned_to_id: The updated assignee ID (only if it should change)
        - notes: Any notes to add to the issue as a comment
        
        Format your response as a valid JSON object with only the fields that should be changed.
        """
        
        try:
            # Convert current issue to formatted string for context
            current_issue_str = json.dumps(current_issue, indent=2)
            user_message = f"""
            Current issue:
            {current_issue_str}
            
            Update instructions:
            {prompt}
            """
            
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message}
                ],
                response_format={"type": "json_object"}
            )
            
            update_data = json.loads(response.choices[0].message.content)
            
            # Ensure at least one field is updated
            if not update_data:
                raise ValueError("No update fields were generated")
            
            return update_data
        except Exception as e:
            error_msg = f"Error generating issue updates: {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)
    
    def analyze_issue(self, issue):
        """
        Analyze a Redmine issue and provide insights
        
        Args:
            issue (dict): The issue data from Redmine
            
        Returns:
            dict: Analysis and insights about the issue
        """
        system_prompt = """
        You are a helpful assistant that analyzes Redmine issues and provides insights.
        
        Generate a JSON object with the following fields:
        - summary: A brief summary of the issue
        - analysis: Detailed analysis of the issue content
        - suggestions: Suggestions for improvement or resolution
        - estimated_complexity: A rating from 1-5 of how complex the issue appears to be
        - estimated_effort: A rating from 1-5 of how much effort may be required to address the issue
        - tags: A list of keywords or tags that could be associated with this issue
        
        Format your response as a valid JSON object.
        """
        
        try:
            # Convert issue to formatted string for analysis
            issue_str = json.dumps(issue, indent=2)
            
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Analyze this Redmine issue:\n{issue_str}"}
                ],
                response_format={"type": "json_object"}
            )
            
            analysis = json.loads(response.choices[0].message.content)
            
            return analysis
        except Exception as e:
            error_msg = f"Error analyzing issue: {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)
