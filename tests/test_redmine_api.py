"""
Tests for the Redmine API integration
"""
import pytest
import responses
import json
from redmine_api import RedmineAPI
from tests.config import (
    TEST_REDMINE_URL,
    TEST_REDMINE_API_KEY,
    TEST_PROJECT_ID,
    TEST_ISSUE_SUBJECT,
    TEST_ISSUE_DESCRIPTION
)


@pytest.fixture
def redmine_api():
    """Create a RedmineAPI instance for testing"""
    return RedmineAPI(TEST_REDMINE_URL, TEST_REDMINE_API_KEY)


@pytest.mark.parametrize("include_trailing_slash", [True, False])
def test_redmine_api_init(include_trailing_slash):
    """Test initializing the RedmineAPI with and without trailing slash"""
    url = TEST_REDMINE_URL
    if include_trailing_slash:
        url = url + "/"
    
    api = RedmineAPI(url, TEST_REDMINE_API_KEY)
    
    # Verify URL has no trailing slash
    assert api.url == TEST_REDMINE_URL.rstrip('/')
    
    # Verify headers are set correctly
    assert api.headers['X-Redmine-API-Key'] == TEST_REDMINE_API_KEY
    assert api.headers['Content-Type'] == 'application/json'


@responses.activate
def test_get_issues(redmine_api):
    """Test getting issues from Redmine"""
    # Mock response
    issues_response = {
        "issues": [
            {
                "id": 1,
                "subject": "Test Issue 1",
                "description": "Test Description 1",
                "project": {"id": 1, "name": "Test Project"}
            },
            {
                "id": 2,
                "subject": "Test Issue 2",
                "description": "Test Description 2",
                "project": {"id": 1, "name": "Test Project"}
            }
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/issues.json",
        json=issues_response,
        status=200
    )
    
    # Test with default parameters
    issues = redmine_api.get_issues()
    assert len(issues) == 2
    assert issues[0]['id'] == 1
    assert issues[0]['subject'] == "Test Issue 1"
    
    # Verify request parameters
    assert len(responses.calls) == 1
    assert "limit=25" in responses.calls[0].request.url
    
    # Reset mock responses
    responses.reset()
    
    # Mock response for filtered issues
    filtered_response = {
        "issues": [
            {
                "id": 1,
                "subject": "Test Issue 1",
                "description": "Test Description 1",
                "project": {"id": 1, "name": "Test Project"}
            }
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/issues.json",
        json=filtered_response,
        status=200
    )
    
    # Test with filters
    issues = redmine_api.get_issues(project_id="1", status_id="1", limit=10)
    assert len(issues) == 1
    
    # Verify request parameters
    assert len(responses.calls) == 1
    assert "project_id=1" in responses.calls[0].request.url
    assert "status_id=1" in responses.calls[0].request.url
    assert "limit=10" in responses.calls[0].request.url


@responses.activate
def test_get_issue(redmine_api):
    """Test getting a specific issue from Redmine"""
    issue_id = 1
    issue_response = {
        "issue": {
            "id": issue_id,
            "subject": "Test Issue",
            "description": "Test Description",
            "project": {"id": 1, "name": "Test Project"},
            "tracker": {"id": 1, "name": "Bug"},
            "status": {"id": 1, "name": "New"},
            "priority": {"id": 2, "name": "Normal"},
            "journals": [{"notes": "Test journal entry"}]
        }
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/issues/{issue_id}.json",
        json=issue_response,
        status=200
    )
    
    issue = redmine_api.get_issue(issue_id)
    assert issue['id'] == issue_id
    assert issue['subject'] == "Test Issue"
    assert 'journals' in issue
    
    # Verify request parameters
    assert len(responses.calls) == 1
    assert "include=journals,attachments,relations,children,watchers" in responses.calls[0].request.url


@responses.activate
def test_create_issue(redmine_api):
    """Test creating an issue in Redmine"""
    issue_response = {
        "issue": {
            "id": 1,
            "subject": TEST_ISSUE_SUBJECT,
            "description": TEST_ISSUE_DESCRIPTION,
            "project": {"id": int(TEST_PROJECT_ID), "name": "Test Project"}
        }
    }
    
    def request_callback(request):
        payload = json.loads(request.body)
        assert payload['issue']['subject'] == TEST_ISSUE_SUBJECT
        assert payload['issue']['description'] == TEST_ISSUE_DESCRIPTION
        assert payload['issue']['project_id'] == TEST_PROJECT_ID
        return (201, {}, json.dumps(issue_response))
    
    responses.add_callback(
        responses.POST,
        f"{TEST_REDMINE_URL}/issues.json",
        callback=request_callback,
        content_type='application/json',
    )
    
    issue = redmine_api.create_issue(
        project_id=TEST_PROJECT_ID,
        subject=TEST_ISSUE_SUBJECT,
        description=TEST_ISSUE_DESCRIPTION
    )
    
    assert issue['id'] == 1
    assert issue['subject'] == TEST_ISSUE_SUBJECT
    
    # Test with additional parameters
    responses.reset()
    
    def request_callback_with_params(request):
        payload = json.loads(request.body)
        assert payload['issue']['subject'] == TEST_ISSUE_SUBJECT
        assert payload['issue']['tracker_id'] == 1
        assert payload['issue']['priority_id'] == 2
        assert payload['issue']['assigned_to_id'] == 3
        return (201, {}, json.dumps(issue_response))
    
    responses.add_callback(
        responses.POST,
        f"{TEST_REDMINE_URL}/issues.json",
        callback=request_callback_with_params,
        content_type='application/json',
    )
    
    issue = redmine_api.create_issue(
        project_id=TEST_PROJECT_ID,
        subject=TEST_ISSUE_SUBJECT,
        description=TEST_ISSUE_DESCRIPTION,
        tracker_id=1,
        priority_id=2,
        assigned_to_id=3
    )
    
    assert issue['id'] == 1


@responses.activate
def test_update_issue(redmine_api):
    """Test updating an issue in Redmine"""
    issue_id = 1
    
    def request_callback(request):
        payload = json.loads(request.body)
        assert payload['issue']['subject'] == "Updated Subject"
        assert payload['issue']['description'] == "Updated Description"
        return (204, {}, "")
    
    responses.add_callback(
        responses.PUT,
        f"{TEST_REDMINE_URL}/issues/{issue_id}.json",
        callback=request_callback,
        content_type='application/json',
    )
    
    result = redmine_api.update_issue(
        issue_id=issue_id,
        subject="Updated Subject",
        description="Updated Description"
    )
    
    assert "message" in result
    assert f"Issue {issue_id} updated successfully" in result["message"]
    
    # Test with additional parameters
    responses.reset()
    
    def request_callback_with_params(request):
        payload = json.loads(request.body)
        assert payload['issue']['subject'] == "Updated Subject"
        assert payload['issue']['tracker_id'] == 1
        assert payload['issue']['priority_id'] == 2
        assert payload['issue']['assigned_to_id'] == 3
        assert payload['issue']['status_id'] == 2
        assert payload['issue']['notes'] == "This is a note"
        return (204, {}, "")
    
    responses.add_callback(
        responses.PUT,
        f"{TEST_REDMINE_URL}/issues/{issue_id}.json",
        callback=request_callback_with_params,
        content_type='application/json',
    )
    
    result = redmine_api.update_issue(
        issue_id=issue_id,
        subject="Updated Subject",
        description=None,  # Test that None values are not included
        tracker_id=1,
        priority_id=2,
        assigned_to_id=3,
        status_id=2,
        notes="This is a note"
    )
    
    assert "message" in result


@responses.activate
def test_get_projects(redmine_api):
    """Test getting projects from Redmine"""
    projects_response = {
        "projects": [
            {"id": 1, "name": "Project 1", "identifier": "project1"},
            {"id": 2, "name": "Project 2", "identifier": "project2"}
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/projects.json",
        json=projects_response,
        status=200
    )
    
    projects = redmine_api.get_projects()
    assert len(projects) == 2
    assert projects[0]['name'] == "Project 1"


@responses.activate
def test_get_trackers(redmine_api):
    """Test getting trackers from Redmine"""
    trackers_response = {
        "trackers": [
            {"id": 1, "name": "Bug"},
            {"id": 2, "name": "Feature"}
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/trackers.json",
        json=trackers_response,
        status=200
    )
    
    trackers = redmine_api.get_trackers()
    assert len(trackers) == 2
    assert trackers[0]['name'] == "Bug"


@responses.activate
def test_get_statuses(redmine_api):
    """Test getting issue statuses from Redmine"""
    statuses_response = {
        "issue_statuses": [
            {"id": 1, "name": "New"},
            {"id": 2, "name": "In Progress"},
            {"id": 3, "name": "Resolved"}
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/issue_statuses.json",
        json=statuses_response,
        status=200
    )
    
    statuses = redmine_api.get_statuses()
    assert len(statuses) == 3
    assert statuses[1]['name'] == "In Progress"


@responses.activate
def test_get_priorities(redmine_api):
    """Test getting issue priorities from Redmine"""
    priorities_response = {
        "issue_priorities": [
            {"id": 1, "name": "Low"},
            {"id": 2, "name": "Normal"},
            {"id": 3, "name": "High"}
        ]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/enumerations/issue_priorities.json",
        json=priorities_response,
        status=200
    )
    
    priorities = redmine_api.get_priorities()
    assert len(priorities) == 3
    assert priorities[2]['name'] == "High"


@responses.activate
def test_api_error_handling(redmine_api):
    """Test error handling in the RedmineAPI"""
    error_response = {
        "errors": ["Project doesn't exist"]
    }
    
    responses.add(
        responses.GET,
        f"{TEST_REDMINE_URL}/issues.json",
        json=error_response,
        status=404
    )
    
    with pytest.raises(Exception) as excinfo:
        redmine_api.get_issues()
    
    assert "Error fetching issues" in str(excinfo.value)