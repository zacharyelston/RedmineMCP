"""
LLM API integration for Redmine Extension.
This module implements the integration with Anthropic's Claude API.
"""

import json
import logging
import os
import requests
from datetime import datetime

logger = logging.getLogger(__name__)

class LLMAPI:
    """
    A wrapper for the Anthropic Claude API to handle LLM tasks
    """
    API_URL = "https://api.anthropic.com/v1/messages"
    
    def __init__(self, api_key):
        """
        Initialize the Claude API client
        
        Args:
            api_key (str): The Claude API key
        """
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json",
            "X-API-Key": api_key,
            "anthropic-version": "2023-06-01"
        }
        logger.debug("Claude API client initialized")
    
    def _make_request(self, messages, system_prompt=None, max_tokens=1000):
        """
        Make a request to the Claude API
        
        Args:
            messages (list): List of message objects
            system_prompt (str, optional): System prompt to set context
            max_tokens (int, optional): Maximum number of tokens to generate
            
        Returns:
            str: The model's response
        """
        data = {
            "model": "claude-3-opus-20240229",
            "messages": messages,
            "max_tokens": max_tokens
        }
        
        if system_prompt:
            data["system"] = system_prompt
        
        try:
            response = requests.post(
                self.API_URL,
                headers=self.headers,
                json=data
            )
            
            if response.status_code != 200:
                logger.error(f"Claude API error: {response.status_code} - {response.text}")
                raise Exception(f"API request failed with status code {response.status_code}: {response.text}")
            
            result = response.json()
            return result["content"][0]["text"]
        
        except Exception as e:
            logger.error(f"Error making Claude API request: {str(e)}")
            raise Exception(f"Failed to communicate with Claude API: {str(e)}")
    
    def generate_issue(self, prompt):
        """
        Generate Redmine issue attributes based on a prompt
        
        Args:
            prompt (str): The user's prompt describing the issue
            
        Returns:
            dict: The generated issue attributes
        """
        logger.info("Generating Redmine issue from prompt")
        
        system_prompt = """
        You are an AI assistant that creates structured Redmine issue data from natural language descriptions.
        
        Your task is to extract key issue attributes from the provided prompt and format them into a JSON structure
        that can be used to create a Redmine issue.
        
        Include the following fields in your response:
        - subject: A clear, concise title for the issue
        - description: A detailed description of the issue
        - tracker_id: The type of issue (1 for Bug, 2 for Feature, 3 for Support, etc.)
        - priority_id: The priority level (1 for Low, 2 for Normal, 3 for High, 4 for Urgent, 5 for Immediate)
        - project_id: Use the project ID provided in the prompt, or default to 1
        - assigned_to_id: User ID of the assignee, if specified, otherwise omit
        
        Respond ONLY with the JSON structure, nothing else. Don't include explanations, notes or other text.
        """
        
        messages = [
            {"role": "user", "content": prompt}
        ]
        
        try:
            response = self._make_request(messages, system_prompt)
            
            # Extract JSON from the response
            try:
                # Try to parse the response directly as JSON
                issue_data = json.loads(response)
            except json.JSONDecodeError:
                # If direct parsing fails, try to extract JSON from markdown code blocks
                import re
                json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', response)
                if json_match:
                    issue_data = json.loads(json_match.group(1))
                else:
                    raise Exception("Could not extract valid JSON from the response")
            
            logger.info("Successfully generated issue data")
            return issue_data
        
        except Exception as e:
            logger.error(f"Error generating issue: {str(e)}")
            raise Exception(f"Failed to generate issue: {str(e)}")
    
    def update_issue(self, prompt, current_issue):
        """
        Generate updated Redmine issue attributes based on a prompt and current issue
        
        Args:
            prompt (str): The user's prompt describing the desired updates
            current_issue (dict): The current issue data from Redmine
            
        Returns:
            dict: The updated issue attributes
        """
        logger.info(f"Updating Redmine issue #{current_issue.get('id')} from prompt")
        
        system_prompt = """
        You are an AI assistant that updates Redmine issues based on natural language descriptions.
        
        Your task is to determine what changes should be made to the existing issue based on the provided prompt.
        
        Compare the current issue data with the requested changes and generate a JSON structure containing
        ONLY the fields that need to be updated. Do not include fields that don't need changing.
        
        Possible fields to update:
        - subject: Issue title
        - description: Issue description
        - tracker_id: Type of issue
        - priority_id: Priority level
        - assigned_to_id: User to assign
        - status_id: Issue status
        - notes: Notes to add (this field is always included as a new note, not replacing existing notes)
        
        Respond ONLY with the JSON structure, nothing else. Don't include explanations, notes or other text.
        """
        
        # Format the current issue as a string for the prompt
        current_issue_str = json.dumps(current_issue, indent=2)
        
        messages = [
            {"role": "user", "content": f"Current issue data:\n{current_issue_str}\n\nRequested updates:\n{prompt}"}
        ]
        
        try:
            response = self._make_request(messages, system_prompt)
            
            # Extract JSON from the response
            try:
                # Try to parse the response directly as JSON
                update_data = json.loads(response)
            except json.JSONDecodeError:
                # If direct parsing fails, try to extract JSON from markdown code blocks
                import re
                json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', response)
                if json_match:
                    update_data = json.loads(json_match.group(1))
                else:
                    raise Exception("Could not extract valid JSON from the response")
            
            logger.info("Successfully generated issue update data")
            return update_data
        
        except Exception as e:
            logger.error(f"Error generating issue update: {str(e)}")
            raise Exception(f"Failed to generate issue update: {str(e)}")
    
    def analyze_issue(self, issue):
        """
        Analyze a Redmine issue and provide insights
        
        Args:
            issue (dict): The issue data from Redmine
            
        Returns:
            dict: Analysis and insights about the issue
        """
        logger.info(f"Analyzing Redmine issue #{issue.get('id')}")
        
        system_prompt = """
        You are an AI assistant that analyzes Redmine issues and provides valuable insights.
        
        Your task is to review the provided issue data and generate a comprehensive analysis that includes:
        
        1. A summary of the key points of the issue
        2. Potential root causes or factors contributing to the issue
        3. Suggested next steps or actions to address the issue
        4. Estimated complexity (Low, Medium, High)
        5. Recommended priority if different from current
        6. Any patterns or similarities to common issues
        
        Format your response as a JSON object with the following structure:
        {
          "summary": "Brief summary of the issue",
          "root_causes": ["Potential cause 1", "Potential cause 2", ...],
          "suggested_actions": ["Action 1", "Action 2", ...],
          "complexity": "Low|Medium|High",
          "recommended_priority": "Low|Normal|High|Urgent|Immediate",
          "patterns": ["Pattern or similar issue 1", "Pattern 2", ...],
          "additional_insights": "Any other relevant observations"
        }
        
        Respond ONLY with the JSON structure, nothing else. Don't include explanations, notes or other text.
        """
        
        # Format the issue as a string for the prompt
        issue_str = json.dumps(issue, indent=2)
        
        messages = [
            {"role": "user", "content": f"Issue data to analyze:\n{issue_str}"}
        ]
        
        try:
            response = self._make_request(messages, system_prompt, max_tokens=2000)
            
            # Extract JSON from the response
            try:
                # Try to parse the response directly as JSON
                analysis_data = json.loads(response)
            except json.JSONDecodeError:
                # If direct parsing fails, try to extract JSON from markdown code blocks
                import re
                json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', response)
                if json_match:
                    analysis_data = json.loads(json_match.group(1))
                else:
                    raise Exception("Could not extract valid JSON from the response")
            
            logger.info("Successfully generated issue analysis")
            return analysis_data
        
        except Exception as e:
            logger.error(f"Error analyzing issue: {str(e)}")
            raise Exception(f"Failed to analyze issue: {str(e)}")