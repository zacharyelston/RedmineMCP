"""
Tests for the LLM API integration
"""
import pytest
import responses
import json
from llm_api import LLMAPI
from tests.config import TEST_CLAUDE_API_KEY


@pytest.fixture
def llm_api():
    """Create a LLMAPI instance for testing"""
    return LLMAPI(TEST_CLAUDE_API_KEY)


def test_llm_api_init():
    """Test initializing the LLMAPI"""
    api = LLMAPI(TEST_CLAUDE_API_KEY)
    
    # Verify API key and headers are set correctly
    assert api.api_key == TEST_CLAUDE_API_KEY
    assert api.headers["x-api-key"] == TEST_CLAUDE_API_KEY
    assert api.headers["anthropic-version"] == "2023-06-01"
    assert api.headers["content-type"] == "application/json"
    
    # Verify the base URL is correct
    assert api.base_url == "https://api.anthropic.com/v1/messages"
    
    # Verify the model is set correctly
    assert api.model == "claude-3-opus-20240229"


@responses.activate
def test_generate_issue(llm_api):
    """Test generating a Redmine issue with Claude"""
    mock_claude_response = {
        "id": "msg_01ABCDEFG",
        "type": "message",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": '{"subject": "Login Error on Production", "description": "Users are receiving 404 errors when attempting to log in on the production environment. This started occurring after the latest deployment.", "project_id": 1, "tracker_id": 1, "priority_id": 3}'
            }
        ],
        "model": "claude-3-opus-20240229",
        "stop_reason": "end_turn",
        "usage": {
            "input_tokens": 213,
            "output_tokens": 85
        }
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=mock_claude_response,
        status=200
    )
    
    prompt = "Create a bug report for a login page error where users receive 404 error after login attempt on production"
    issue_data = llm_api.generate_issue(prompt)
    
    # Verify the issue data is parsed correctly
    assert issue_data["subject"] == "Login Error on Production"
    assert "404 errors" in issue_data["description"]
    assert issue_data["project_id"] == 1
    assert issue_data["tracker_id"] == 1
    assert issue_data["priority_id"] == 3
    
    # Verify the request parameters
    assert len(responses.calls) == 1
    request_body = json.loads(responses.calls[0].request.body)
    assert request_body["model"] == "claude-3-opus-20240229"
    assert request_body["messages"][0]["role"] == "user"
    assert request_body["messages"][0]["content"] == prompt
    assert "system" in request_body
    assert "Generate a JSON object" in request_body["system"]


@responses.activate
def test_update_issue(llm_api):
    """Test updating a Redmine issue with Claude"""
    mock_claude_response = {
        "id": "msg_01ABCDEFG",
        "type": "message",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": '{"subject": "Updated: Login Error on Production", "priority_id": 4, "status_id": 2, "notes": "Updated the priority to urgent and status to in progress."}'
            }
        ],
        "model": "claude-3-opus-20240229",
        "stop_reason": "end_turn",
        "usage": {
            "input_tokens": 345,
            "output_tokens": 95
        }
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=mock_claude_response,
        status=200
    )
    
    current_issue = {
        "id": 1,
        "subject": "Login Error on Production",
        "description": "Users are receiving 404 errors when attempting to log in.",
        "project": {"id": 1, "name": "Test Project"},
        "tracker": {"id": 1, "name": "Bug"},
        "status": {"id": 1, "name": "New"},
        "priority": {"id": 3, "name": "High"}
    }
    
    prompt = "Change the priority to urgent and status to in progress"
    update_data = llm_api.update_issue(prompt, current_issue)
    
    # Verify the update data is parsed correctly
    assert update_data["subject"] == "Updated: Login Error on Production"
    assert update_data["priority_id"] == 4
    assert update_data["status_id"] == 2
    assert "Updated the priority" in update_data["notes"]
    
    # Verify the request parameters
    assert len(responses.calls) == 1
    request_body = json.loads(responses.calls[0].request.body)
    assert request_body["model"] == "claude-3-opus-20240229"
    assert "system" in request_body
    assert "You will be provided with the current state of an issue" in request_body["system"]
    assert json.dumps(current_issue) in request_body["messages"][0]["content"]
    assert prompt in request_body["messages"][0]["content"]


@responses.activate
def test_analyze_issue(llm_api):
    """Test analyzing a Redmine issue with Claude"""
    mock_claude_response = {
        "id": "msg_01ABCDEFG",
        "type": "message",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": '{"summary": "Login system error causing 404 responses", "analysis": "This appears to be a routing issue in the authentication system. The 404 error indicates that the login endpoint might be misconfigured or not available.", "suggestions": ["Check the web server configuration", "Verify the login route is correctly defined", "Review recent deployment changes"], "estimated_complexity": 3, "estimated_effort": 2, "tags": ["authentication", "routing", "deployment", "404-error"]}'
            }
        ],
        "model": "claude-3-opus-20240229",
        "stop_reason": "end_turn",
        "usage": {
            "input_tokens": 321,
            "output_tokens": 165
        }
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=mock_claude_response,
        status=200
    )
    
    issue = {
        "id": 1,
        "subject": "Login Error on Production",
        "description": "Users are receiving 404 errors when attempting to log in.",
        "project": {"id": 1, "name": "Test Project"},
        "tracker": {"id": 1, "name": "Bug"},
        "status": {"id": 1, "name": "New"},
        "priority": {"id": 3, "name": "High"}
    }
    
    analysis = llm_api.analyze_issue(issue)
    
    # Verify the analysis data is parsed correctly
    assert analysis["summary"] == "Login system error causing 404 responses"
    assert "routing issue" in analysis["analysis"]
    assert len(analysis["suggestions"]) == 3
    assert analysis["estimated_complexity"] == 3
    assert analysis["estimated_effort"] == 2
    assert "authentication" in analysis["tags"]
    
    # Verify the request parameters
    assert len(responses.calls) == 1
    request_body = json.loads(responses.calls[0].request.body)
    assert request_body["model"] == "claude-3-opus-20240229"
    assert "system" in request_body
    assert "You are a helpful assistant that analyzes Redmine issues" in request_body["system"]
    assert json.dumps(issue) in request_body["messages"][0]["content"]


@responses.activate
def test_error_handling(llm_api):
    """Test error handling in the LLMAPI"""
    # Test for API errors
    error_response = {
        "error": {
            "type": "authentication_error",
            "message": "Invalid API key"
        }
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=error_response,
        status=401
    )
    
    with pytest.raises(Exception) as excinfo:
        llm_api.generate_issue("Create a test issue")
    
    assert "Error generating issue" in str(excinfo.value)
    
    # Test for malformed JSON response
    responses.reset()
    
    mock_invalid_json_response = {
        "id": "msg_01ABCDEFG",
        "type": "message",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": 'This is not valid JSON'
            }
        ],
        "model": "claude-3-opus-20240229"
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=mock_invalid_json_response,
        status=200
    )
    
    with pytest.raises(Exception) as excinfo:
        llm_api.generate_issue("Create a test issue")
    
    assert "Error generating issue" in str(excinfo.value)
    
    # Test for missing required fields
    responses.reset()
    
    mock_missing_fields_response = {
        "id": "msg_01ABCDEFG",
        "type": "message",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": '{"project_id": 1}'
            }
        ],
        "model": "claude-3-opus-20240229"
    }
    
    responses.add(
        responses.POST,
        "https://api.anthropic.com/v1/messages",
        json=mock_missing_fields_response,
        status=200
    )
    
    with pytest.raises(Exception) as excinfo:
        llm_api.generate_issue("Create a test issue")
    
    assert "missing a subject" in str(excinfo.value)