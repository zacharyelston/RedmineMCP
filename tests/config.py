"""
Configuration for tests
"""
import os

# Test configuration
TEST_REDMINE_URL = os.environ.get('TEST_REDMINE_URL', 'http://localhost:3000')
TEST_REDMINE_API_KEY = os.environ.get('TEST_REDMINE_API_KEY', 'test_redmine_api_key')
TEST_CLAUDE_API_KEY = os.environ.get('TEST_CLAUDE_API_KEY', 'test_claude_api_key')

# Test data
TEST_PROJECT_ID = os.environ.get('TEST_PROJECT_ID', '1')  # Default project ID in a new Redmine instance
TEST_ISSUE_SUBJECT = "Test Issue from MCP"
TEST_ISSUE_DESCRIPTION = "This is a test issue created by the Model Context Protocol extension automated tests."